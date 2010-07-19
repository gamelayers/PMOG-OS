# == Schema Information
# Schema version: 20081220201004
#
# Table name: users
#
#  id                        :string(36)    default(""), not null, primary key
#  login                     :string(255)   
#  email                     :string(255)   
#  crypted_password          :string(40)    
#  salt                      :string(40)    
#  created_at                :datetime      
#  updated_at                :datetime      
#  last_login_at             :datetime      
#  remember_token            :string(255)   
#  remember_token_expires_at :datetime      
#  visits_count              :integer(11)   default(0)
#  time_zone                 :string(255)   default("Etc/UTC")
#  identity_url              :string(255)   
#  forename                  :string(255)   
#  surname                   :string(255)   
#  url                       :string(255)   
#  date_of_birth             :date          
#  gender                    :string(1)     
#  country                   :string(255)   
#  datapoints                :integer(11)   default(0)
#  primary_association       :string(255)   
#  secondary_association     :string(255)   
#  tertiary_association      :string(255)   
#  total_datapoints          :integer(11)   default(0), not null
#  beta_key_id               :integer(11)   
#  motto                     :string(255)   
#  privacy_level             :string(255)   default("public")
#  current_level             :integer(11)   default(1)
#  posts_count               :integer(11)   default(0), not null
#  average_rating            :integer(11)   default(0)
#  total_ratings             :integer(11)   default(0)
#  ratings_count             :integer(11)   default(0)
#  lifetime_pings            :integer(11)   default(0)
#  available_pings           :integer(11)   default(0)
#

# Buddies are Users too
class Buddy < ActiveRecord::Base
	set_table_name 'users'

  acts_as_cached

  # Note the single quotes and backslashes must be present for this to work - duncan 18/11/07
  has_many :assets, :as => :attachable, :finder_sql => 'SELECT * FROM assets WHERE (assets.attachable_id = \'#{self.id}\' AND assets.attachable_type = \'User\')', :order => 'assets.created_at ASC'

  has_one :user_level, :foreign_key => 'user_id'
  has_many :ratings, :as => :rateable, :dependent => :destroy # i can has ratings?
	has_and_belongs_to_many	:users, :order => 'last_login_at DESC'

  @@private_api_fields = []
  @@included_api_associations = []
  
  after_save :expire_cache

  def to_param
    login
  end

  def has_avatar?     
    ! self.assets.empty?
  end
  
  def has_avatar?
    assets.size > 0
  end
  
  def last_active
    last_login = DailyLogIn.find( :first, :conditions => { :user_id => self.id }, :order => 'created_at DESC' )
    last_login.nil? ? nil : last_login.created_at
  end
  
  # FIXME this is just hackery to protect against bad record combinations
  # there should be a cleaner way to validate these somehow
  def current_level
    if self.user_level.nil?
      self.user_level = UserLevel.create
      self.user_level.auto_assign_primary
    end
    self.user_level.primary
  end

  def primary_class
    if self.user_level.nil?
      self.user_level = UserLevel.create
      self.user_level.auto_assign_primary
    end
    self.user_level.primary_class
  end

  # Lists existing connections between the current Buddy and another user
  def existing_connections( user_id )
    Buddy.find_by_sql( [ 'select buddy_id, user_id, type from buddies_users where buddy_id = ? and user_id = ?', self.id, user_id ] )
  end

  # add with self as BUDDY, current_user as USER
  def add(current_user, connection_type)
    self.connection.insert( "insert into buddies_users (buddy_id, user_id, accepted, type, requires_approval, created_at, updated_at) values ('#{self.id}', '#{current_user.id}', 1, '#{connection_type}', 0, '#{Time.now.to_s(:db)}', '#{Time.now.to_s(:db)}')" )

    current_user.reward_pings Ping.value("Make Contact")

    Event.record :context => "#{connection_type}_added",
      :user_id => current_user.id,
      :recipient_id => self.id,
      :message => " made <a href=\"#{current_user.pmog_host}/users/#{ self.login}\">#{self.login}</a> #{(connection_type=='ally' ? 'an':'a')} #{connection_type == 'acquaintance' ? 'contact' : connection_type}"

    expire_memcache current_user, connection_type
  end

  def update(current_user, connection_type)
    self.connection.update( "update buddies_users set type = '#{connection_type}', accepted = 1 where buddy_id = '#{self.id}' and user_id = '#{current_user.id}'")
    expire_memcache current_user, connection_type
  end

  # Kill a buddy connection
  def remove current_user
    self.connection.update( "update buddies_users set accepted = 0 where buddy_id = '#{self.id}' and user_id = '#{current_user.id}'" )
    expire_memcache current_user, 'all'
  end

  protected
  # helper method centered around expiring the current_user's buddy cache, not this buddy's cache
  # this is a hugely expensive call, but this is the kind of data that users demand be up to date
  def expire_memcache current_user, type
    #FIXME use type to hit less of these
    current_user.expire_cache("contacts_")
    current_user.expire_cache("acquainted_with_#{self.id}")
    current_user.expire_cache("rivaled_with_#{self.id}")
    current_user.expire_cache("allied_with_#{self.id}")
    current_user.expire_cache("contacts_count_")
    current_user.expire_cache("contacts__raw_ids")
    current_user.expire_cache("contacts_ally")
    current_user.expire_cache("contacts_rival")
    current_user.expire_cache("contacts_acquaintance")
    current_user.expire_cache("contacts_count_ally")
    current_user.expire_cache("contacts_count_rival")
    current_user.expire_cache("contacts_count_acquaintance")
    current_user.expire_cache("contacts_ally_raw_ids")
    current_user.expire_cache("contacts_rival_raw_ids")
    current_user.expire_cache("contacts_acquaintance_raw_ids")
    current_user.expire_cache("connected_with_#{self.id}")

    # we need a real user here to match memcache namespaces
    #new_buddy = User.find(:first, :conditions => { :login => self.login })

    self.expire_cache("followers_")
#    self.expire_cache("acquainted_by_#{current_user.id}")
#    self.expire_cache("rivaled_by_#{current_user.id}")
#    self.expire_cache("allied_by_#{current_user.id}")
    self.expire_cache("followers_count_")
#    self.expire_cache("followers__raw_ids")
    self.expire_cache("followers_ally")
    self.expire_cache("followers_rival")
    self.expire_cache("followers_acquaintance")
    self.expire_cache("followers_count_ally")
    self.expire_cache("followers_count_rival")
    self.expire_cache("followers_count_acquaintance")
#    self.expire_cache("followers_ally_raw_ids")
#    self.expire_cache("followers_rival_raw_ids")
#    self.expire_cache("followers_acquaintance_raw_ids")
  end

end
