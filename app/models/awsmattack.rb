# Awsm-Attacks are created when a user loots a DP Card or trips a Mine on the web
# - awsmattack.user is the player who tripped the mine/looted the dp card
# - awsmattack.creator is the player who deployed the mine/laid the dp card
class Awsmattack < ActiveRecord::Base
  belongs_to :user # player triggering event
  belongs_to :creator, :class_name => 'User' # player creating event
  belongs_to :location
  #belongs_to :old_location

  acts_as_cached

  validates_presence_of :location_id, :user_id, :context, :message => 'cannot be null'

  def before_create
    self.id = create_uuid
    # Denormalised dates, so that we can query the anticapted large volume data across
    # different time periods faster than using DATE() in MySQL - duncan 20/01/09
    self.week = TzTime.zone.now.strftime('%W') rescue Date.today.strftime('%W')
    self.month = TzTime.zone.now.strftime('%m') rescue Date.today.strftime('%m')
    self.year = TzTime.zone.now.strftime('%Y') rescue Date.today.strftime('%Y')
  end
  
  class << self
    # Record an awsm-attack, tieing together the player who created the mine/dp card
    # and the player who looted it, along with the url where it happened.
    def create_and_deposit(user, creator, location, context)
      user.awsmattacks.create( :creator_id => creator.id, :location_id => location.id, :context => context )
      expire_cache('awsm_this_week_15')
      expire_cache('attack_this_week_15')
    end
    
    # The top +type+ (awsm/attack)for +period+
    # - if this is slow with more records, just pull out all the records and calculate it in ruby
    def top(type, period, limit = 15)
      get_cache("#{type}_#{period}_#{limit}", :ttl => ttl_for(period)) do
        context = context_for(type)
        start_date, end_date = dates_for(period)
        find_by_sql( [  "SELECT awsmattacks.id, 
                                count(awsmattacks.id) as count, 
                                awsmattacks.location_id, 
                                awsmattacks.created_at 
                         FROM awsmattacks, locations
                         WHERE context = ? 
                         AND awsmattacks.created_at BETWEEN ? AND ? 
                         AND locations.id = awsmattacks.location_id
                         AND locations.url NOT LIKE 'http://pmog.com%'
                         AND locations.url NOT LIKE 'http://thenethernet.com%'
                         GROUP BY awsmattacks.location_id 
                         ORDER BY count DESC, created_at DESC 
                         LIMIT ?", context, start_date, end_date, limit ] )
      end
    end

    # The most recent +type+ (awsm/attack)
    def recent(type, limit = 15)
      get_cache("#{type}_#{limit}", :ttl => 5.minutes) do
        context = context_for(type)
        find_by_sql( [  "SELECT awsmattacks.*
                         FROM awsmattacks, locations
                         WHERE context = ?
                         AND locations.id = awsmattacks.location_id
                         AND locations.url NOT LIKE 'http://pmog.com%'
                         AND locations.url NOT LIKE 'http://thenethernet.com%'
                         ORDER BY awsmattacks.created_at DESC
                         LIMIT ?", context, limit ] )
      end
    end

    # The latest Awsms and Attacks for +user+
    def latest_for(user, page = 1, per_page = 100)
      get_cache("latest_for_#{user}_#{page}_#{per_page}") do
        user.awsmattacks.find(:all, :order => 'created_at DESC').paginate(:page => page, :per_page => per_page)
      end
    end

    # The latest Awsms for +user+
    def latest_awsms_for(user, page = 1, per_page = 100)
      get_cache("latest_awsms_ for_#{user}_#{page}_#{per_page}") do
        user.awsmattacks.find(:all, :conditions => {:context => 'dp_card'}, :order => 'created_at DESC').paginate(:page => page, :per_page => per_page)
      end
    end
    
    # The latest Attacks for +user+
    def latest_attacks_for(user, page = 1, per_page = 100)
      get_cache("latest_attacks_for_#{user}_#{page}_#{per_page}") do
        user.awsmattacks.find(:all, :conditions => {:context => 'mine'}, :order => 'created_at DESC').paginate(:page => page, :per_page => per_page)
      end
    end

    private
    # Converts awsm and attack into the relevant +context+
    def context_for(type)
      if type.downcase == 'awsm'
        return 'dp_card'
      elsif type.downcase == 'attack'
        return 'mine'
      end
    end

    # Returns the start and end dates for +period+
    def dates_for(period)
      if period == 'today' || period.nil?
        start_date = Date.today.at_beginning_of_day
        end_date = Date.tomorrow.at_beginning_of_day
      elsif period == 'yesterday'
        start_date = Date.yesterday.at_beginning_of_day
        end_date = Date.today.at_beginning_of_day
      elsif period == 'this_week'
        start_date = 0.weeks.ago.at_beginning_of_week.to_time
        end_date = 0.weeks.ago.at_end_of_week.to_time
      elsif period == 'last_week'
        start_date = 1.week.ago.at_beginning_of_week.to_time
        end_date = 1.week.ago.at_end_of_week.to_time
      end
      [start_date, end_date]
    end

    # Returns the caching ttl for +period+
    def ttl_for(period)
      if period == 'today' || period.nil?
        ttl = 5.minutes
      elsif period == 'yesterday'
        ttl = 1.week
      elsif period == 'this_week'
        ttl = 10.minutes
      elsif period == 'last_week'
        ttl = 1.week
      end
      ttl
    end
  end
end
