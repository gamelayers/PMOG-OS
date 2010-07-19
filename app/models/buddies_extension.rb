# Keeping the User model tidy by extending the Buddy has_many association with a module
# See http://api.rubyonrails.com/classes/ActiveRecord/Associations/ClassMethods.html (Association extensions)
# Nb. we don't eager-load the assets here, as that fails and we take care of that using finder_sql in buddy.rb
#
# Refactor this any way you like, if you'd like, but here's a good pointer:
# http://railsjitsu.com/programming-beautiful-ruby-on-rails-code-part-2

#NOTE: huge recatoring done on 09-02-28 by alex as part of getting nethernet contacts functional for release
# fee free to change anything i did as a part of that

module BuddiesExtension
  include ActionView::Helpers::DateHelper
  # We need these helpers for rendering the buddy's avatar to the extension.
  include AvatarHelper
  # Note that the cached methods only set user ids to cache.
  # It's fast eough to pull them from the database in one hit
  # at the end, and we do that without scope also.

  def has_any?
    execute("SELECT count(buddy_id) FROM buddies_users WHERE user_id='#{proxy_owner.id}'").fetch_row[0].to_i > 0
  end

  def cached_contacts(type = nil, limit = 10)
    cached_buddies('contacts', type, limit)
  end

  def cached_followers(type = nil, limit = 10)
    cached_buddies('followers', type, limit)
  end

  def any_followers?
    cached_followers(nil, nil).size > 0
  end

  def rivals
    @owner.buddies.cached_contacts('rival')
  end

  # A slimmed down version without sensitive keys
  def rivals_for_json
    make_json_contacts("rival")
  end

  def allies
    @owner.buddies.cached_contacts('ally')
  end

  # A slimmed down version without sensitive keys
  def allies_for_json
    make_json_contacts("ally")
  end

  def contacts
    @owner.buddies.cached_contacts('acquaintance')
  end

  def contacts_for_json
    make_json_contacts("acquaintance")
  end

  # Just returns a list of buddy ids
  # - filters by +type+ is required
  def cached_contacts_ids(type = nil)
    get_cache( "contacts_#{type}_raw_ids", :ttl => 2.hours ) {
      if type.nil?
        buddy_ids = find_by_sql(['SELECT users.id AS user_id FROM buddies_users, users WHERE buddies_users.buddy_id = users.id AND user_id = ? AND accepted = 1', proxy_owner.id])
      else
        buddy_ids = find_by_sql(['SELECT users.id AS user_id FROM buddies_users, users WHERE buddies_users.buddy_id = users.id AND user_id = ? AND type = ? AND accepted = 1', proxy_owner.id, type])
      end
      buddy_ids.collect{ |b| b.user_id }.uniq.sort_by{ rand }
    }
  end

  def cached_contacts_count(type = nil)
    proxy_owner.get_cache("contacts_count_#{type}", :ttl => 2.hours ) do
      # match on user_id (happens automatically from this scope)
      if type.nil?
        count(:conditions => ['accepted = 1' ] )
      else
        count(:conditions => ['accepted = 1 AND type = ?', type ] )
      end
    end
  end

  def cached_followers_count(type = nil)
    proxy_owner.get_cache("followers_count_#{type}", :ttl => 2.hours ) do
      # match on buddy_id (gotta do this one manually)
      if type.nil?
        execute("SELECT count(buddy_id) FROM buddies_users WHERE buddy_id='#{proxy_owner.id}' AND accepted=1").fetch_row[0].to_i
      else
        execute("SELECT count(buddy_id) FROM buddies_users WHERE buddy_id='#{proxy_owner.id}' AND accepted=1 AND type='#{type}'").fetch_row[0].to_i
      end
    end
  end

  # Stores only the buddy ids in cache, so that they fit.
  # Note that we then pull each buddy from cache, and
  # call load_assets to pull the cached assets from cache too
  def cached_buddies(method, type = nil, limit = nil)
    # we can't cache the limit; there is no way to expire it as you can't iterate acorss memcache keys so we won't know which limit values are even set
    # (this would take place in buddy.expire_cache, which is already expensive enough)
    if(limit.nil?)
      ids = proxy_owner.get_cache("#{method}_#{type}", :ttl => 2.hours) {
        extract_user_ids_from( self.send("get_#{method}", type, limit) )
      }
    else
      ids = extract_user_ids_from(self.send("get_#{method}", type, limit))
    end

    if (ids.nil? or ids.empty?)
      return []
    else
      items = []
      # Hack, get_caches doesn't respect disabling memcache
      if ActsAsCached.config[:disabled]
        items = load_assets(Buddy.find(ids))
      else
        items = load_assets(Buddy.get_caches(ids, :ttl => 2.hours).values)
      end

      # Sort the contacts so that the most recently logged in player is first and so on.
      return items.sort_by{|i|i && i.send(:last_login_at) || 5.years.ago}.reverse
    end
  end

  # Both +accepted+ and +pending+ could be written with just one SQL query, however that query
  # can result in a huge 'User load' which uses an IN, which means MySQL won't use an index
  # and instead just filestorts. This way around, we avoid join tables and pull out the relevant
  # buddies, then fire off a number of User.find() queries which can be cached in multiple
  # places automatically (in the SQL Cache, and in the ActiveRecord Cache) - duncan 21/01/09
  # Note that if no +type+ is passed in, we get all accepted contacts, allies and rivals,
  # then grab a unique selection. This is mainly because the contact system has been
  # broken by design a number of times, so this is the best way of grabbing the data we need
  # without causing a filesort in the database, or returning rubbish data - duncan 19/02/00
  def get_contacts(type = nil, limit = 10)
    limit_condition = (limit.nil? ? '' : ' LIMIT ' + limit.to_s)
    order_by_condition = ' ORDER BY users.last_login_at '
    if type.nil?
      buddy_ids = find_by_sql(['SELECT users.id AS user_id FROM buddies_users, users WHERE buddies_users.buddy_id = users.id AND user_id = ? AND accepted = 1' + order_by_condition + limit_condition, proxy_owner.id])
      buddy_ids = buddy_ids.collect{ |b| b.user_id }
    else
      buddy_ids = find_by_sql(['SELECT users.id AS user_id FROM buddies_users, users WHERE accepted = 1 AND buddies_users.buddy_id = users.id AND user_id = ? AND type = ?' + order_by_condition + limit_condition, proxy_owner.id, type])
      buddy_ids = buddy_ids.collect{ |b| b.user_id }
    end
    buddy_ids.collect{ |id| User.caches(:find, :with => id) rescue nil }.reject{ |b| b.nil? }
  end

  # this is the same as get_contacts except the buddy_id and user_id checks are swapped
  def get_followers(type = nil, limit = 10)
    limit_condition = (limit.nil? ? '' : ' LIMIT ' + limit.to_s)
    if type.nil?
      buddy_ids = find_by_sql(['SELECT users.id AS user_id FROM buddies_users, users WHERE accepted = 1 AND buddies_users.buddy_id = ? AND user_id = users.id' + limit_condition, proxy_owner.id])
      buddy_ids = buddy_ids.collect{ |b| b.user_id }
    else
      buddy_ids = find_by_sql(['SELECT users.id AS user_id FROM buddies_users, users WHERE accepted = 1 AND buddies_users.buddy_id = ? AND user_id = users.id AND type = ?' + limit_condition, proxy_owner.id, type])
      buddy_ids = buddy_ids.collect{ |b| b.user_id }
    end
    buddy_ids.collect{ |id| User.caches(:find, :with => id) rescue nil }.reject{ |b| b.nil? }
  end

  def was_connected_to? other_user
    proxy_owner.get_cache("connected_with_#{other_user.id}", :ttl => 2.hours) do
      buddy_ids = find_by_sql(['SELECT users.id AS user_id FROM buddies_users, users WHERE buddies_users.buddy_id = users.id AND user_id = ?', proxy_owner.id])
      buddy_ids.flatten.collect{ |b| b.user_id }.uniq.include? other_user.id
    end
  end

  # Is this user allied with +other_user+
  def allied_with?(other_user)
    proxy_owner.get_cache("allied_with_#{other_user.id}", :ttl => 2.hours) do
      cached_contacts( 'ally', nil).collect{ |ally| ally.id }.uniq.include? other_user.id
    end
  end

  # Is this user rivalled with +other_user+
  def rivaled_with?(other_user)
    proxy_owner.get_cache("rivaled_with_#{other_user.id}", :ttl => 2.hours) do
      cached_contacts( 'rival', nil).collect{ |rival| rival.id }.uniq.include? other_user.id
    end
  end

  # Is this user acquainted with +other_user+
  def acquainted_with?(other_user)
    proxy_owner.get_cache("acquainted_with_#{other_user.id}", :ttl => 2.hours) do
      cached_contacts( 'acquaintance', nil ).collect{ |acquaintance| acquaintance.id }.uniq.include? other_user.id
    end
  end

  # Returns a list of the last 5 active user ids
  def recently_active(limit = 5)
    proxy_owner.get_cache("#{proxy_owner.id}_recently_active", :ttl => 1.hour) do
      cached_contacts.sort_by(&:updated_at).reverse[0..limit].collect do |u|
        { :avatar_mini => avatar_path_for_user(:user => u, :size => 'mini'),
          :avatar_small => avatar_path_for_user(:user => u, :size => 'small'),
          :id => u.id,
          :current_level => u.current_level,
        :login => u.login }
      end
    end
  end

  def relationship(other_user = nil)
    relation = "none";

    unless other_user.nil?
      if other_user == proxy_owner
        relation = "self"
      elsif allied_with? other_user
        relation = "ally"
      elsif rivaled_with? other_user
        relation = "rival"
      elsif acquainted_with? other_user
        relation = "contact"
      end
    end

    return relation
  end


  # Eager loading of assets just doesn't seem to work with the Buddy/User setup
  # we have here. So we can call +load_assets+ to set that up manually.
  def load_assets(buddies)
    buddies.each_with_index do |buddy,index|
      buddies[index].caches(:assets, :ttl => 2.hours)
    end
  end

  # Pull out a list of user ids from an array of buddies.
  # Used mainly to cut down on the amount of data we store in cache.
  def extract_user_ids_from(buddies)
    buddies.collect{ |b| b.id }
  end

  def make_json_contacts(type)
    @owner.buddies.cached_contacts(type).map do |u|
      { :avatar_mini => avatar_path_for_user(:user => u, :size => 'mini'),
        :avatar_small => avatar_path_for_user(:user => u, :size => 'small'),
        :id => u.id,
        :login => u.login,
        :last_active => u.last_active.nil? ? 'a while' : time_ago_in_words(u.last_active),
        :current_level => u.current_level,
        :primary_association => u.primary_class
      }
    end
  end
end
