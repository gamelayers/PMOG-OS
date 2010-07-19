class Stat
  acts_as_cached

  # Executes all relevant Stat methods
  # - only executes methods named calculate_*
  # - caches all of the relevant stats so that they can be viewed without hurting the db
  # - also relies on each method using cache_fu and slave_setup to offset the database cost
  def self.prepare_all
    self.methods.reject{ |method| method !~ /^calculate_.*/ }.each do |method|
      self.send(method)
    end
  end

  # Num of players signing up per day, going back 60 days
  def self.calculate_new_signups_per_day
    self.slave_and_cache(User, 'new_signups_per_day', 1.day) do
      User.find_by_sql( ['SELECT YEAR(users.created_at) as year, 
                          MONTH(users.created_at) as month, 
                          DAY(users.created_at) as day, 
                          COUNT(users.id) as sum 
                          FROM users 
                          WHERE users.created_at >= ? 
                          GROUP BY DATE(users.created_at)', 60.days.ago.to_s(:db)] )
    end
  end

  # Num of players pinging our message API per day
  def self.calculate_connected_users_per_day
    self.slave_and_cache(DailyActivity, 'connected_users_per_day', 1.day) do
      DailyActivity.find_by_sql( [ 'SELECT YEAR(created_on) as year, 
                                    MONTH(created_on) as month, 
                                    DAY(created_on) as day, 
                                    COUNT(id) as count, 
                                    DATE(created_on) AS date,
                                    created_on 
                                    FROM daily_activities 
                                    WHERE created_on != DATE(?) 
                                    GROUP BY created_on', Date.today ] )
    end
  end

  # % of players who are pinging our message API per day
  def self.calculate_percentage_connected_users_per_day
    self.slave_and_cache(DailyActivity, 'percentage_connected_users_per_day', 1.day) do
      connected_users = self.calculate_connected_users_per_day
      percentages = connected_users.collect { |u| 
        total_users = User.find_by_sql( [ 'select count(*) as sum from users where created_at <= ?', u.created_on ] )
        ( (u.count.to_f / total_users[0].sum.to_f) * 100).round
      }
      [connected_users, percentages]
    end
  end
 
  # Num of players pinging our message API per hour, in the last week
  def self.calculate_connected_users_per_hour
    self.slave_and_cache(HourlyActivity, 'connected_users_per_hour', 1.day) do
      HourlyActivity.find(  :all, 
                            :select => 'count(distinct(user_id)) as sum, DATE(created_at) as created_on, hour', 
                            :conditions => [ 'created_at > ?', 1.weeks.ago.to_s(:db) ], 
                            :group => 'DATE(created_at), hour', 
                            :order => 'created_at' )
    end
  end

  # % of players with 0 contacts, with 1 contact, with 5 contacts, 10 contacts
  def self.calculate_percentage_spread_of_contacts
    self.slave_and_cache(Buddy, 'percentage_spread_of_contacts', 1.day) do
      # TBC
      # - do we count allies, rivals and acquaintances separately?
    end
  end

  # # of people making a rating of another player each day
  # - if we want number of users rating per day, use count(distinct(user_id)) as count
  def self.calculate_number_of_user_ratings_per_day
    self.slave_and_cache(Buddy, 'number_of_user_ratings_per_day', 1.day) do
      Buddy.find_by_sql( [ 'SELECT count(id) as count,
                            YEAR(created_at) as year,
                            MONTH(created_at) as month, 
                            DAY(created_at) as day
                            FROM ratings
                            WHERE rateable_type = ?
                            GROUP BY DATE(created_at)', 'User' ] )
    end
  end

  # # of people making a rating of a mission each day
  def self.calculate_number_of_mission_ratings_per_day
    self.slave_and_cache(Mission, 'number_of_mission_ratings_per_day', 1.day) do
      Mission.find_by_sql( [ 'SELECT count(id) as count,
                              YEAR(created_at) as year,
                              MONTH(created_at) as month, 
                              DAY(created_at) as day
                              FROM ratings
                              WHERE rateable_type = ?
                              GROUP BY DATE(created_at)', 'Mission' ] )
    end
  end

  # # of players sending a PMail per day
  # - excludes PMails sent by PMOG
  # - counts the distinct user ids, not the total # of messages sent
  # - excludes PMails sent today, so the graphs go up
  def self.calculate_number_of_players_sending_pmail_per_day
    self.slave_and_cache(Message, 'number_of_players_sending_pmail_per_day', 1.day) do
      @pmog_user = User.find_by_email('self@pmog.com')
      Message.find_by_sql( [ 'SELECT count(distinct(user_id)) as count,
                              YEAR(created_at) as year,
                              MONTH(created_at) as month, 
                              DAY(created_at) as day
                              FROM messages
                              WHERE user_id != ?
                              AND created_at  != DATE(?) 
                              GROUP BY DATE(created_at)', @pmog_user.id, Date.today ] ) 
    end 
  end

  # # of PMails sent this week
  def self.calculate_number_of_pmails_sent_this_week
    self.slave_and_cache(Message, 'number_of_pmails_sent_this_week', 1.day) do
      Message.find( :all, 
                    :select => 'COUNT(user_id) AS count, 
                                DATE(created_at) AS date', 
                    :conditions => ['created_at BETWEEN ? AND ?', 0.weeks.ago.at_beginning_of_week.to_time, 0.weeks.ago.at_end_of_week.to_time], 
                    :group => 'DATE(created_at)', 
                    :order => 'DATE(created_at) ASC' )
    end
  end

  # # of PMails sent last week
  def self.calculate_number_of_pmails_sent_last_week
    self.slave_and_cache(Message, 'number_of_pmails_sent_last_week', 1.day) do
      Message.find( :all, 
                    :select => 'COUNT(user_id) AS count, 
                                DATE(created_at) AS date', 
                    :conditions => ['created_at BETWEEN ? AND ?', 1.week.ago.at_beginning_of_week.to_time, 1.week.ago.at_end_of_week.to_time], 
                    :group => 'DATE(created_at)', 
                    :order => 'DATE(created_at) ASC' )
    end
  end

  # # of PMails sent in total
  def self.calculate_number_of_pmails_sent_all_time
    self.slave_and_cache(Message, 'number_of_pmails_sent_all_time', 1.day) do
      Message.find( :all, 
                    :select => 'COUNT(user_id) AS count, 
                                DATE(created_at) AS date', 
                    :group => 'DATE(created_at)', 
                    :order => 'DATE(created_at) ASC' )
    end
  end

  # # of player who are active per day
  # - activity is defined as content creation within pmog
  # - See http://hospital.pmog.com/browse/METRICS-20 for more
  # - Calculates the total number of active users for each day, and then
  #   stores that number in the +active_users+ table as a form of denormalisation.
  # - Only calculates active_user numbers for dates that are no in the
  #   active_users table, otherwise is just fetches that # from the database.
  # - Note, to run this from scratch you'll need to disable caching
  #   until the active_users table has filled up, otherwise the
  #   tool_users_per_day stat will be too big for memcached.
  def self.calculate_active_users
    self.slave_and_cache(ToolUse, 'active_users', 1.day) do
      latest_date = ActiveUser.latest_date
      mines = self.calculate_user_tool_uses_per_day('mines', latest_date)
      crates = self.calculate_user_tool_uses_per_day('crates', latest_date)
      portals = self.calculate_user_tool_uses_per_day('portals', latest_date)
      lightposts = self.calculate_user_tool_uses_per_day('lightposts', latest_date)
      watchdogs = self.calculate_user_tool_uses_per_day('watchdogs', latest_date)
      st_nicks = self.calculate_user_tool_uses_per_day('st_nicks', latest_date)
      pmails = self.calculate_user_pmails_sent_per_day(latest_date)
      missions = self.calculate_user_missions_created_per_day(latest_date)
      posts = self.calculate_user_forum_posts_per_day(latest_date)

      # Create a hash of :date => user_ids
      dates_users = {}
      [mines, crates, portals, lightposts, watchdogs, st_nicks, pmails, missions, posts].each do |item|
        item.each do |i|
          if dates_users[i.date].nil?
            dates_users[i.date] = [i.user_ids]
          else
            dates_users[i.date] << i.user_ids
          end
        end
      end

      # Now convert the hash into :date => # of uniq user_ids
      active_users = {}
      dates_users.each do |date|
        active_users[date[0]] = date[1].flatten.uniq.size
      end

      # Denormalise the data in the active_users table so that subsequent 
      # viewings of the graph don't require us to process the same 
      # information over and over again. Note that we do this outside of 
      # the slave_and_cache block since ActiveUser.create is INSERTing records
      # into the database, and we can't do that on the slave
      ActiveUser.transaction do
        active_users.each do |u|
          ActiveUser.create(:date=> u[0], :count => u[1]) unless ActiveUser.exists?(:date => u[0])
        end
      end
    end
    # If the above is cached, this is all that runs. Just returns a hash
    # of :date => num of users active for use in a graph
    ActiveUser.data_for_graph
  end

  # of player who are active per day
  def self.calculate_active_users_per_week
    # active users, all time, by week, unique
  end

  # Num of players who have responded to an event in PMOG
  # - this should work the same as active users with a 
  #   denormalised table called 'reactive_users'
  # - only 'taken' mission stumbles are counted, not queued or dismissed
  # - See http://hospital.pmog.com/browse/METRICS-21
  def self.calculate_reactive_users
    self.slave_and_cache(User, 'reactive_users_per_day', 1.day) do
      latest_date = ReactiveUser.latest_date
      # Note that we call calculate_user_tool_reactions_per_day separately for each
      # different context, to avoid creating a query that uses an IN, since that will
      # most likely result in a filesort with MySQL - duncan 29/12/08
      taken_portals = self.calculate_user_tool_reactions_per_day('portal_used', latest_date)

      looted_crates = self.calculate_user_tool_reactions_per_day('crate_looted', latest_date)
      looted_crates << self.calculate_user_tool_reactions_per_day('puzzle_crate_looted', latest_date)
      looted_crates << self.calculate_user_tool_reactions_per_day('exploding_crate_deflected', latest_date)
      looted_crates << self.calculate_user_tool_reactions_per_day('exploding_crate_detonated', latest_date)

      tripped_mines = self.calculate_user_tool_reactions_per_day('mine_tripped', latest_date)
      tripped_mines << self.calculate_user_tool_reactions_per_day('mine_deflected', latest_date)

      # If you want to include dismissed and queued missions that are stumbled upon, uncomment below...
      stumbled_missions = self.calculate_user_mission_stumbles_per_day('take', latest_date)
      #stumbled_missions << self.calculate_user_mission_stumbles_per_day('queue', latest_date)
      #stumbled_missions << self.calculate_user_mission_stumbles_per_day('dismiss', latest_date)

      # Create a hash of :date => user_ids
      dates_users = {}
      [taken_portals.flatten, looted_crates.flatten, tripped_mines.flatten, stumbled_missions.flatten].each do |item|
        item.each do |i|
          if dates_users[i.date].nil?
            dates_users[i.date] = [i.user_ids]
          else
            dates_users[i.date] << i.user_ids
          end
        end
      end

      # Now convert the hash into :date => # of uniq user_ids
      reactive_users = {}
      dates_users.each do |date|
        reactive_users[date[0]] = date[1].flatten.uniq.size
      end

      reactive_users.each do |u|
        ReactiveUser.create(:date=> u[0], :count => u[1]) unless ReactiveUser.exists?(:date => u[0])
      end
    end
    # If the above is cached, this is all that runs.
    # Returns hash of :date => num of users reacting
    ReactiveUser.data_for_graph
  end

  # Aggregates the connected, active and reactive users into one graph
  # - returns a hash of :connected, :active and :reactive
  # - adds in +max+ and +dates+ variables for use in the graph
  def self.calculate_connected_active_reactive_per_day
    self.slave_and_cache(User, 'connected_active_reactive_per_day', 1.day) do
      @users = {
        :connected => self.calculate_connected_users_per_day,
        :active => self.calculate_active_users,
        :reactive => self.calculate_reactive_users,
      }

      max = 0
      dates = []
      @users.keys.each do |type|
        tmp_max = @users[type].collect{ |u| u.count.to_i }.max
        tmp_dates = @users[type].collect{ |u| u.date.to_s }

        max = tmp_max if tmp_max > max
        dates << tmp_dates.collect{ |d| d.to_s }
      end

      # Munge the three sets of data so that we have no dates
      # without data for connected, active or reactive users
      normalised_users = { :connected => {}, :active => {}, :reactive => {} }
      @users.keys.each do |type|
        @users[type].each do |u|
          normalised_users[type][u.date.to_s] = u.count
        end
      end

      @users[:max] = max
      @users[:dates] = dates.flatten.uniq.sort

      @users[:dates].each do |date|
        [:connected, :active, :reactive].each do |type|
          normalised_users[type][date.to_s] = 0 unless normalised_users[type][date.to_s]
        end
      end

      normalised_users[:max] = @users[:max]
      normalised_users[:dates] = @users[:dates]
      normalised_users
    end
  end

  # The number of users who deployed a +tool+ each day
  # - uses count(distinct(user_id))
  # - excludes today's data so that our graphs go up
  # - +user_column+ can be specified for things like grenades.perp_id
  def self.calculate_number_of_users_deploying_tool_per_day(tool = 'portals', user_column = 'user_id')
    self.slave_and_cache(Portal, "number_of_users_deploying_tool_per_day_#{tool}", 1.day) do
      tool.classify.constantize.find_by_sql(  ["SELECT COUNT(DISTINCT(#{user_column})) AS count, 
                                                DATE(created_at) AS date 
                                                FROM #{tool}
                                                WHERE DATE(created_at) != ?
                                                GROUP BY DATE(created_at)", Date.today ] )
    end
  end

  # The number of +tool+ deployed each day
  # - excludes today's data so that our graphs go up
  def self.calculate_number_of_tools_deployed_per_day(tool = 'portals')
    self.slave_and_cache(Portal, "number_of_tools_deployed_per_day_#{tool}", 1.day) do
      tool.classify.constantize.find_by_sql(  ["SELECT COUNT(id) AS count, 
                                                DATE(created_at) AS date 
                                                FROM #{tool}
                                                WHERE DATE(created_at) != ?
                                                GROUP BY DATE(created_at)", Date.today ] )
    end
  end

  # The number of users who drew a portal each day
  # - uses count(distinct(user_id))
  # - excludes today's data so that our graphs go up
  def self.calculate_number_of_users_drawing_portals_per_day
    self.slave_and_cache(Portal, 'number_of_users_drawing_portals_per_day', 1.day) do
      Portal.find_by_sql(  ['SELECT COUNT(DISTINCT(user_id)) AS count, 
                              DATE(created_at) AS date 
                              FROM portals 
                              WHERE DATE(created_at) != ?
                              GROUP BY DATE(created_at)', Date.today ] )
    end
  end

  # The number of portals drawn each day
  # - excludes today's data so that our graphs go up
  def self.calculate_number_of_portals_drawn_per_day
    self.slave_and_cache(Portal, 'number_of_portals_drawn_per_day', 1.day) do
      Portal.find_by_sql(  ['SELECT COUNT(id) AS count, 
                              DATE(created_at) AS date 
                              FROM portals 
                              WHERE DATE(created_at) != ?
                              GROUP BY DATE(created_at)', Date.today ] )
    end
  end
  # which players used +tool_name+ per day
  # - returns a list of unique user_ids each day
  # - uses +latest_date+  to narrow the search if required
  # - excludes today's data as we only want to count complete days
  def self.calculate_user_tool_uses_per_day(tool_name = 'mines', latest_date = Date.today)
    self.slave_and_cache(ToolUse, "user_tool_uses_per_day_#{tool_name}_#{latest_date}", 1.day) do
      tool = Tool.find_by_name(tool_name)
      ToolUse.find_by_sql(  ['SELECT DISTINCT(user_id) AS user_ids, 
                              DATE(created_at) AS date 
                              FROM tool_uses 
                              WHERE tool_id = ? 
                              AND usage_type = ? 
                              AND DATE(created_at) != ?
                              AND created_at > ? 
                              GROUP BY user_id, DATE(created_at)', tool.id, 'tool', Date.today, latest_date] )
    end
  end

  # which players reacted/interacted with a tool per day
  # - returns a list of unique user_ids each day
  # - users +latest_date+ to narrow the search if required
  # - excludes today's data as we only want to count complete days
  # - uses the events table and the +context+ field to calculate the stats
  def self.calculate_user_tool_reactions_per_day(context = 'mines', latest_date = Date.today)
    self.slave_and_cache(Event, "user_tool_reactions_per_day_#{context}_#{latest_date}", 1.day) do
      Event.find_by_sql(  [ 'SELECT DISTINCT(user_id) AS user_ids, 
                             DATE(created_at) AS date 
                             FROM events
                             WHERE context = ? 
                             AND DATE(created_at) != ?
                             AND created_at > ? 
                             GROUP BY user_id, DATE(created_at)', context, Date.today, latest_date] )
    end
  end

  # which players sent a pmail per day
  # - returns a list of unique user_ids for each day
  # - uses +latest_date+  to narrow the search if required
  # - excludes today's data as we only want to count complete days
  # - excludes pmails sent by the PMOG user
  def self.calculate_user_pmails_sent_per_day(latest_date = Date.today)
    self.slave_and_cache(Message, "user_pmails_sent_per_day_#{latest_date}", 1.day) do
      @pmog_user = User.find_by_email('self@pmog.com')
      Message.find_by_sql(  ['SELECT DISTINCT(user_id) AS user_ids, 
                              DATE(created_at) AS date 
                              FROM messages 
                              WHERE DATE(created_at) != ?
                              AND user_id != ?
                              AND created_at > ? 
                              GROUP BY user_id, DATE(created_at)', Date.today, @pmog_user.id, latest_date] )
    end
  end

  # which players created a mission per day
  # - returns a list of unique user_ids for each day
  # - uses +latest_date+  to narrow the search if required
  # - excludes today's data as we only want to count complete days
  # - Note that we use ToolUse and not Mission, since a call to 
  #   mission.user_ids further up the chain prompts a sequence of 
  #   AR loads from the missionatings table, which is not what we want.
  def self.calculate_user_missions_created_per_day(latest_date = Date.today)
    self.slave_and_cache(ToolUse, "user_missions_created_per_day_#{latest_date}", 1.day) do
      ToolUse.find_by_sql( ['SELECT DISTINCT(user_id) as user_ids,
                             DATE(created_at) AS date
                             FROM missions 
                             WHERE DATE(created_at) != ?
                             AND created_at > ?
                             GROUP BY user_id, DATE(created_at)', Date.today, latest_date] )
    end
  end

  # which players reacted to a mission they stumbled upon per day
  # - returns a list of unique user_ids for each day
  # - uses +latest_date+  to narrow the search if required
  # - excludes today's data as we only want to count complete days
  def self.calculate_user_mission_stumbles_per_day(action = 'take', latest_date = Date.today)
    self.slave_and_cache(MissionStat, "user_mission_stumbles_per_day_#{latest_date}", 1.day) do
      MissionStat.find_by_sql( ['SELECT DISTINCT(user_id) AS user_ids,
                                 DATE(created_at) AS date
                                 FROM mission_stats
                                 WHERE context = ?
                                 AND action = ?
                                 AND DATE(created_at) != ?
                                 AND created_at > ?
                                 GROUP BY user_id, DATE(created_at)', 'stumble', action, Date.today, latest_date] )
    end
  end

  # which players posted in the forums per day
  # - returns a list of unique user_ids for each day
  # - uses +latest_date+  to narrow the search if required
  # - excludes today's data as we only want to count complete days
  def self.calculate_user_forum_posts_per_day(latest_date = Date.today)
    self.slave_and_cache(Post, "user_forum_posts_per_day_#{latest_date}", 1.day) do
      Post.find_by_sql( ['SELECT DISTINCT(user_id) as user_ids,
                          DATE(created_at) AS date
                          FROM posts 
                          WHERE DATE(created_at) != ?
                          AND created_at > ?
                          GROUP BY user_id, DATE(created_at)', Date.today, latest_date] )
    end
  end

  # how many players took a portal each day
  def self.calculate_number_of_players_taking_portals_per_day
    self.slave_and_cache(Portal, 'number_of_players_taking_portals_per_day', 1.day) do
      Portal.find_by_sql(  ["SELECT COUNT(DISTINCT(user_id)) AS count, 
                             DATE(created_at) AS date 
                             FROM transportations
                             WHERE DATE(created_at) != ?
                             GROUP BY DATE(created_at)", Date.today ] )
    end
  end

  # how many players laid a giftcard each day
  def self.calculate_number_of_players_laying_giftcards_per_day
    self.slave_and_cache(Giftcard, 'number_of_players_laying_giftcards_per_day', 1.day) do
      Giftcard.find_by_sql(  ["SELECT COUNT(DISTINCT(user_id)) AS count, 
                              DATE(created_at) AS date 
                              FROM giftcards
                              WHERE DATE(created_at) != ?
                              GROUP BY DATE(created_at)", Date.today ] )
    end
  end

  # how many players completed a mission each day
  def self.calculate_number_of_players_completing_missions_per_day
    self.slave_and_cache(Mission, 'number_of_players_completing_missions_per_day', 1.day) do
      Mission.find_by_sql(  ["SELECT COUNT(DISTINCT(user_id)) AS count, 
                              DATE(created_at) AS date 
                              FROM missionatings
                              WHERE DATE(created_at) != ?
                              GROUP BY DATE(created_at)", Date.today ] )
    end
  end

  # how many players created a mission each day
  def self.calculate_number_of_players_creating_missions_per_day
    self.slave_and_cache(Mission, 'number_of_players_creating_missions_per_day', 1.day) do
      Mission.find_by_sql(  ["SELECT COUNT(DISTINCT(user_id)) AS count, 
                              DATE(created_at) AS date 
                              FROM missions
                              WHERE DATE(created_at) != ?
                              GROUP BY DATE(created_at)", Date.today ] )
    end
  end

  # how many missions were created each day
  def self.calculate_number_of_missions_created_per_day
    self.slave_and_cache(Mission, 'number_of_missions_created_per_day', 1.day) do
      Mission.find_by_sql(  ["SELECT COUNT(id) AS count, 
                              DATE(created_at) AS date 
                              FROM missions
                              WHERE DATE(created_at) != ?
                              GROUP BY DATE(created_at)", Date.today ] )
    end
  end

  # how many mines were triggered each day
  def self.calculate_mines_triggered_all_time
    self.slave_and_cache(ToolUse, 'number_of_mines_triggered_all_time', 1.day) do
      tool_id = Tool.find_by_name('mines').id
      ToolUse.find(:all, 
                   :select => 'COUNT(user_id) AS count, DATE(created_at) AS date', 
                   :conditions => ['tool_id = ?', tool_id], :group => 'DATE(created_at)', :order => 'DATE(created_at) ASC' )
    end
  end

  private
  # Executes database queries against the slave server, and caches the result
  # - this must *only* be used with database SELECTS
  def self.slave_and_cache(model, key, ttl)
    get_cache(key, :ttl => ttl) do
      model.slave_setup do
        yield
      end 
    end
  end
end
