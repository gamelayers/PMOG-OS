# User events triggered by active and passive gameplay.
# - note the explicit Event.find here, using just a find/find_by_sql
#   means we end up with duplicate scoping of user_ids, etc - duncan 17/12/08
module EventsExtension
  # Caches +latest+
  def cached_latest(limit = 5)
    get_cache( "latest_#{limit}_#{proxy_owner.id}", :ttl => 180.minutes ) { latest(limit) }
  end

  # Caches +news_feed+
  def cached_news_feed(limit = 20)
    get_cache( "news_feed_#{limit}_#{proxy_owner.id}", :ttl => 180.minutes ) { news_feed(limit) }
  end

  # Caches +your_news_feed_
  def cached_your_news_feed(limit = 20)
    get_cache( "your_news_feed_#{limit}_#{proxy_owner.id}", :ttl => 180.minutes ) { your_news_feed(limit) }
  end

  # Caches +your_triggered_feed_
  def cached_your_triggered_feed(limit = 20)
    get_cache( "your_triggered_feed_#{limit}_#{proxy_owner.id}", :ttl => 180.minutes ) { your_triggered_feed(limit) }
  end

  # Caches +your_combined_feed_
  def cached_your_combined_feed(limit = 20)
    get_cache( "your_combined_feed_#{limit}_#{proxy_owner.id}", :ttl => 180.minutes ) { your_combined_feed(limit) }
  end

  # Caches +acquaintances_news_feed+
  def cached_acquaintances_news_feed(limit = 20)
    get_cache( "acquaintances_news_feed_#{limit}_#{proxy_owner.id}", :ttl => 180.minutes ) { acquaintances_news_feed(limit) }
  end

  # Caches +news_feed_for+
  def cached_news_feed_for(type, limit = 20)
    get_cache( "news_feed_for_#{type}_#{limit}_#{proxy_owner.id}", :ttl => 180.minutes ) { news_feed_for(type, limit) }
  end

  # Because acquaintances is hard to type
  def cached_contacts_news_feed(limit = 20)
    cached_acquaintances_news_feed(limit)
  end

  # Just the latest +limit+ events
  def latest(limit = 5)
    load_assets( Event.find( :all, :limit => limit ) )
  end

  # A Facebook style news feed, listing events from you and your +buddies+
  # - eager loads users without a join query
  # - alternatives to consider (avoiding a filesort at all costs):
  # - pick 3 random buddies, then extract their last 5 events, then extract your latest 5 events, and sort the results by created_at:
  # - pick x random buddies, call events.cached_your_news_feed for each of them, then munge the results and return
  # - sort your cached buddies by recently_active, pick the top x and grab their last n events in disparate queries
  #   then mash that all together to make a feed
  def news_feed(limit = 20)
    # Create an array of the user ids of you and your buddies
    buddy_ids = proxy_owner.buddies.cached_contacts_ids[0..limit]
    buddy_ids << proxy_owner.id

    # Get the basic event information
    events = Event.find_by_sql( [ 'SELECT * FROM events WHERE events.user_id IN (?) AND created_at > ? ORDER BY events.created_at DESC LIMIT ?', buddy_ids, 24.hours.ago, limit ] )
    events.collect{ |e| e.user.login }
    events
  end

  # Returns a feed for the given +type+ of buddies
  def news_feed_for(type, limit = 20)
    buddy_ids = proxy_owner.buddies.cached_contacts_ids(type)[0..limit]
    return [] if buddy_ids.empty?
    Event.find(:all,
      :conditions => ['events.recipient_id IN (?) AND events.created_at > ?',buddy_ids, 24.hours.ago],
      :joins => "LEFT JOIN users ON events.user_id=users.id",
      :select => "events.*, users.login AS user_login",
      :order => "events.created_at DESC",
      :limit => limit)
  end

  # Just your latest +limit+ events
  # - uses find_by_sql else Rails wraps this up with duplicate clauses
  #   as if it's a named_scope, because of the user.events association - duncan 17/04/09
  def your_news_feed(limit = 20)
    #Event.find(:all,
      #:conditions => { :user_id => proxy_owner.id },
      #:joins => "LEFT JOIN users ON events.user_id=users.id",
      #:select => "events.*, users.login AS user_login, 1 AS test",
      #:order => "created_at DESC",
      #:limit => limit)
    Event.find_by_sql(["SELECT events.*, users.login AS user_login FROM events LEFT JOIN users ON events.user_id = users.id WHERE events.user_id = ? ORDER BY created_at DESC LIMIT ?", proxy_owner.id, limit])
  end

  def your_triggered_feed(limit = 20)
    Event.find(:all,
      :conditions => { :recipient_id => proxy_owner.id },
      :joins => "LEFT JOIN users ON events.user_id=users.id",
      :select => "events.*, users.login AS user_login",
      :order => "created_at DESC",
      :limit => limit)
  end

  # Your events as a creator or recipient
  # - using recipient_id = ? OR user_id = ? is slow and hard to index
  # - split this into two queries and munge the results
  def your_combined_feed(limit = 20)
    as_user = Event.find(:all,
                          :conditions => [ 'user_id = ?', proxy_owner.id ],
                          :joins => "LEFT JOIN users ON events.user_id=users.id",
                          :select => "events.*, users.login AS user_login",
                          :order => "created_at DESC",
                          :limit => limit)

    as_recipient = Event.find(:all,
                              :conditions => [ 'recipient_id = ?', proxy_owner.id ],
                              :joins => "LEFT JOIN users ON events.user_id=users.id",
                              :select => "events.*, users.login AS user_login",
                              :order => "created_at DESC",
                              :limit => limit)
    events = []
    events << as_user[0..9]
    events << as_recipient[0..9]
    events.flatten.sort_by{ |e| e.created_at }.reverse[0..limit-1]
  end

  # A Facebook style news feed, listing events from your +buddies+ but not *you*
  # - eager loads users without a join query
  def acquaintances_news_feed(limit = 20)
    buddy_ids = proxy_owner.buddies.cached_contacts_ids[0..limit]
    events = Event.find_by_sql( [ 'SELECT * FROM events WHERE events.user_id IN (?) AND created_at > ? ORDER BY events.created_at DESC LIMIT ?', buddy_ids, 24.hours.ago, limit ] )
    events.collect{ |e| e.user.login }
    events
  end

  # Who is your nemesis? The player whose mines you have tripped the most.
  # - recipient_id is the user who laid the mine, user_id the one who tripped it
  # - contexts are mine_tripped and mine_deflected
  # - a nemesis must have mined you 4 or more times
  def nemesis
    get_cache( "nemesis_#{proxy_owner.id}" ) do
      nemesis = triggered_by_you(['mine_tripped','mine_deflected'])
      nemesis.empty? ? nil : nemesis.first.recipient
    end
  end

  # Who is your punching bag? The player who has tripped the most of your mines.
  def punching_bag
    get_cache( "punching_bag_#{proxy_owner.id}" ) do
      punching_bag = triggered_by_others(['mine_tripped','mine_deflected'])
      punching_bag.empty? ? nil : punching_bag.first.user
    end
  end

  # Who is your DP Momma? The player whose crates have you looted the most.
  def dp_momma
    get_cache( "dp_momma_#{proxy_owner.id}" ) do
      dp_momma = triggered_by_you(['crate_looted','puzzle_crate_looted'])
      dp_momma.empty? ? nil : dp_momma.first.recipient
    end
  end

  # Who is your Ward? The player who has looted the most of your crates.
  def ward
    get_cache( "ward_#{proxy_owner.id}" ) do
      ward = triggered_by_others(['crate_looted','puzzle_crate_looted'])
      ward.empty? ? nil : ward.first.user
    end
  end

  # Who is your Spin Doctor? The player whose portals you have taken the most.
  def spin_doctor
    get_cache( "spin_doctor_#{proxy_owner.id}" ) do
      spin_doctor = triggered_by_you('portal_used')
      spin_doctor.empty? ? nil : spin_doctor.first.recipient
    end
  end

  # Who is your Follower? The player who has taken the most of your portals.
  def follower
    get_cache( "follower_#{proxy_owner.id}" ) do
      follower = triggered_by_others('portal_used')
      follower.empty? ? nil : follower.first.user
    end
  end

  # Who is your Trailblazer? The player whose missions you have completed the most.
  def trailblazer
    get_cache( "trailblazer_#{proxy_owner.id}" ) do
      trailblazer = triggered_by_you('mission_completed')
      trailblazer.empty? ? nil : trailblazer.first.recipient
    end
  end

  # Who is your Apprentice? The player who has completed the most of your missions.
  def apprentice
    get_cache( "apprentice_#{proxy_owner.id}" ) do
      apprentice = triggered_by_others('mission_completed')
      apprentice.empty? ? nil : apprentice.first.user
    end
  end

  # Who is your Mark? The player whose St Nicks you have triggered most often.
  def mark
    get_cache( "mark_#{proxy_owner.id}" ) do
      mark = triggered_by_you('st_nick_activated')
      mark.empty? ? nil : mark.first.recipient
    end
  end

  # Who is your Prey? The player who has been caught by your St Nicks most often.
  def prey
    get_cache( "st_nick_activated_#{proxy_owner.id}" ) do
      prey = triggered_by_others('st_nick_activated')
      prey.empty? ? nil : prey.first.user
    end
  end

  protected
  # Pull in the users and recipients, along with their assets, ideally
  # from cache, as we didn't eager load them in the query
  def load_assets(news_feed)
    news_feed.each do |feed|
      next feed.user.nil?
      feed.caches(:user, :ttl => 1.week)
      feed.user.caches(:assets, :ttl => 1.week)
    end

    news_feed.each do |feed|
      next feed.recipient.nil?
      feed.caches(:recipient, :ttl => 1.week)
      feed.recipient.caches(:assets, :ttl => 1.week)
    end
    news_feed
  end

  # Finds the +recipient+ whose events you have triggered the most
  # - contexts is a list of event contexts to include
  # - recipient_id is the user who deployed the tool, user_id the one who activated it
  # - there must be four or more events for the user to be considered
  def triggered_by_you(contexts)
    Event.find_by_sql(['SELECT * FROM events, users WHERE events.user_id = ? AND events.context IN (?) AND events.recipient_id = users.id GROUP BY recipient_id HAVING count(events.id) >= 4 ORDER BY count(events.id), events.created_at DESC LIMIT 1', proxy_owner.id, contexts])
  end

  # Finds the +user+ who has triggered the most of your events
  # - contexts is a list of event contexts to include
  # - recipient_id is the user who deployed the tool, user_id the one who activated it
  # - there must be four or more events for the user to be considered
  def triggered_by_others(contexts)
    Event.find_by_sql(['SELECT * FROM events, users WHERE events.recipient_id = ? AND events.context IN (?) AND events.user_id = users.id GROUP BY user_id HAVING count(events.id) >= 4 ORDER BY count(events.id), events.created_at DESC LIMIT 1', proxy_owner.id, contexts])
  end
end
