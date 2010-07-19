class Aggstat < ActiveRecord::Base
  HOUR = 0
  DAY = 1
  WEEK = 2
  MONTH = 3
  YEAR = 4

  PERIOD_CONV = { HOUR => "hour", DAY => "day", WEEK => "week", MONTH => "month", YEAR => "year" }

  def self.get_bounds(period, now)
    stime = eval("now.beginning_of_#{Aggstat::PERIOD_CONV[period]}")
    etime = eval("stime.end_of_#{Aggstat::PERIOD_CONV[period]}")
    #puts stime.to_s(:db), etime.to_s(:db)
    #puts stime.utc.to_s(:db), etime.utc.to_s(:db)
    return stime.utc.to_s(:db), etime.utc.to_s(:db)
  end

  def count_new_users
    self.new_users = User.count(:id, :conditions => ['created_at >= ? and created_at <= ?', @stime, @etime])
  end

  def count_users_logged_in
    self.users_logged_in = User.count(:id, :conditions => ['last_login_at >= ? and last_login_at <= ?', @stime, @etime])
  end

  def count_users_first_time_connected
    self.users_first_time_connected = UserActivity.count(:user_id, :conditions => ['created_at >= ? and created_at <= ?', @stime, @etime])
  end

  def count_users_connected
    self.users_connected = UserActivity.count(:user_id, :conditions => ['updated_at >= ? and updated_at <= ?', @stime, @etime])
  end

  def self.count_downloaded_toolbars(period)
  end

  def self.count_installed_toolbars(period)
  end

  def self.count_users_logged_in_toolbar(period)
  end

  def self.count_users_active(period)
  end

  def self.count_users_reactive(period)
  end

  def count_users_using_tools
    # created_at, user_id, tool_id
    self.users_using_tools = ToolUse.count(:user_id, :conditions => ['created_at >= ? and created_at <= ?', @stime, @etime], :distinct => true)
  end

  def count_tools_used
    self.tools_used = ToolUse.count(:id, :conditions => ['created_at >= ? and created_at <= ?', @stime, @etime])
  end

  def self.count_urls_deployed_on(period)
    #tools_used = Event.count(:location_id, :conditions => ['created_at >= ? and created_at <= ?', @stime, @etime], :distinct => true)
  end

  def self.count_tlds_deployed_on(period)
  end

  def count_missions_created
    self.missions_created = Mission.count(:id, :conditions => ['created_at >= ? and created_at <= ? and is_active = 1', @stime, @etime])
  end

  def count_users_creating_missions
    self.users_creating_missions = Mission.count(:user_id, :conditions => ['created_at >= ? and created_at <= ?', @stime, @etime], :distinct => true)
  end

  def count_missions_taken
    # created_at , action, context
    self.missions_taken = MissionStat.count(:id, :conditions => ['created_at >= ? and created_at <= ? and action = ?', @stime, @etime, 'take'])
  end

  def count_users_taking_missions
    # created_at, action, user_id
    self.users_taking_missions = MissionStat.count(:user_id, :conditions => ['created_at >= ? and created_at <= ? and action = ?', @stime, @etime, 'take'], :distinct => true)
  end

  def count_missions_dismissed
    self.missions_taken = MissionStat.count(:id, :conditions => ['created_at >= ? and created_at <= ? and action = ?', @stime, @etime, 'dismiss'])
  end

  def count_users_dismissing_missions
    self.users_taking_missions = MissionStat.count(:user_id, :conditions => ['created_at >= ? and created_at <= ? and action = ?', @stime, @etime, 'dismiss'], :distinct => true)
  end

  def count_missions_queued
    self.missions_taken = MissionStat.count(:id, :conditions => ['created_at >= ? and created_at <= ? and action = ?', @stime, @etime, 'queue'])
  end

  def count_users_queueing_missions
    self.users_taking_missions = MissionStat.count(:user_id, :conditions => ['created_at >= ? and created_at <= ? and action = ?', @stime, @etime, 'queue'], :distinct => true)
  end

  def count_missions_completed
    self.missions_completed = Missionating.count(:mission_id, :conditions => ['created_at >= ? and created_at <= ?', @stime, @etime])
  end

  def count_users_completing_missions
    self.users_completing_missions = Missionating.count(:user_id, :conditions => ['created_at >= ? and created_at <= ?', @stime, @etime], :distinct => true)
  end

  def count_events
    self.events = Event.count(:id, :conditions => ['created_at >= ? and created_at <= ?', @stime, @etime])
  end

  def count_pmails_sent
    self.pmails_sent = Message.count(:id, :conditions => ['created_at >= ? and created_at <= ?', @stime, @etime])
  end

  def count_users_sending_pmails
    self.users_sending_pmails = Message.count(:user_id, :conditions => ['created_at >= ? and created_at <= ?', @stime, @etime], :distinct => true)
  end

  def count_forum_posts
    self.forum_posts = Post.count(:id, :conditions => ['created_at >= ? and created_at <= ?', @stime, @etime])
  end

  def count_users_posting_to_forums
    # user_id, created_at
    self.users_posting_to_forums = Post.count(:user_id, :conditions => ['created_at >= ? and created_at <= ?', @stime, @etime], :distinct => true)
  end

  def count_users_rating_users
    # rateable_type, created_at, user_id
    self.users_rating_users = Rating.count(:user_id, :conditions => ['created_at >= ? and created_at <= ? and rateable_type = ?', @stime, @etime, 'User'], :distinct => true)
  end

  def count_users_rating_missions
    self.users_rating_users = Rating.count(:user_id, :conditions => ['created_at >= ? and created_at <= ? and rateable_type = ?', @stime, @etime, 'Mission'], :distinct => true)
  end

  def _inner_count_users_at_level
    #UserLevel.count(:id, :conditions => ['created_at >= ? and created_at <= ? and  = ?', @stime, @etime, 'Mission'])
  end

  def self.count_users_level
  10.times { |x| eval("users_level_#{x} = _inner_count_users_at_level(period, x)") }
  end

  def count_user_total
    self.user_total = User.count(:id)
  end

  def count_mission_total
    self.mission_total = Mission.count(:id)
  end

  def count_pmail_total
    self.pmail_total = 0 #Message.count(:id)
  end

  def count_events_total
    self.events_total = 0 #Event.count(:id)
  end

  def count_tld_total
    #
  end

  def self.count_nethertweets(period)
  end


  # # # ##  # #

  def self.update_stats(period, day=Time.now)
    Aggstat::run_stats(period, day)
  end


  def set_bounds(period, stat_on)
    @stime, @etime = Aggstat::get_bounds(period, stat_on)
  end

  def self.run_stats(period, day)
    day = Time.parse(day) if day.class == String
    day = day.beginning_of_day

    stime, etime = Aggstat::get_bounds(period, day) # first find old record if it exists

    the_stat = nil
    the_stat = Aggstat.find(:first, :conditions => ['stat_on = ? and period = ?', day.to_s(:db), period])
    the_stat ||= Aggstat.new(:period => period, :stat_on => day)

    the_stat.set_bounds(period, day)

    the_stat.methods.each do |amethod|
      if amethod =~ /^count_/
        #puts "Working on the_state.#{amethod}"
        begin
          eval("the_stat.#{amethod}")
        rescue ActiveRecord::StatementInvalid
          puts "Missing method #{amethod} or table"
        end
      end
    end
    #puts the_stat.new_users.to_yaml
    the_stat.save!
  end

  def self.do_stats(period=DAY, day=Time.now.yesterday)
    Aggstat::run_stats(period, day)
  end

  def self.do_today_stats
    Aggstat::do_stats(DAY, Time.now)
  end

  def self.do_daily_stats
    Aggstat::do_stats(DAY)
  end

  def self.do_weekly_stats
    Aggstat::do_stats(WEEK)
  end

  def self.do_monthly_stats
    Aggstat::do_stats(MONTH)
  end

  def self.do_yearly_stats
    Aggstat::do_stats(YEAR)
  end

end
