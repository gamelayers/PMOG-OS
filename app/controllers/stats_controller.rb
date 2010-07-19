class StatsController < ApplicationController
  before_filter :login_required
  #before_filter :authenticate
  permit 'site_admin'
  require 'gruff'
  caches_action :stats
  
  # Anything in here that uses YEAR/MONTH/DAY functions in MySQL should be rewritten to just pull out the created_at/created_on
  # date, and converted using model.created_at.year, model.created_at.month, model.created_at.day, etc
  ACTIVE_USERS_SQL = 'select YEAR(created_on) as year, MONTH(created_on) as month, DAY(created_on) as day, count(id) as sum from daily_activities group by created_on'
  def index
    redirect_to :action => :view
  end

  def tool_usage_graph
    title = "Tools used per day"
    subheading = "Users (" + User.count.to_s + " total)"
    
    @tool_uses = User.caches( :find_by_sql, :with => 'select created_at, count(id) as sum from tool_uses where tool_uses.usage_type = \'tool\' group by DATE(created_at)' )
    graph_data = @tool_uses.collect { |tool_use| tool_use.sum.to_i }

    labels = {}
    @tool_uses.collect{ |tool_use| tool_use.created_at.day + "/" + tool_use.created_at.month + "/" + tool_use.created_at.year}.each_with_index do |tool_use_date, index|
      labels[index] = tool_use_date if index % 14 == 0
    end

    filename = "tool_usage_graph.png"
    create_graph("Line", title, subheading, graph_data, labels, filename)
  end

  def virality_signup_graph
    title = "Viral Signups per day"
    subheading = "Users (" + User.count.to_s + " total)"
    
    @signups = User.find_by_sql( "select YEAR(users.created_at) as year, MONTH(users.created_at) as month, DAY(users.created_at) as day, count(users.id) as sum from users, beta_keys where users.beta_key_id = beta_keys.id and beta_keys.user_id != '4630774e-93bb-11dc-bd1d-00163e4ab66d' and users.beta_key_id is not null group by DATE(users.created_at)" )
    graph_data = @signups.collect { |signup| signup.sum.to_i }

    labels = {}
    @signups.collect{ |signup| signup.day + "/" + signup.month + "/" + signup.year}.each_with_index do |signup_date, index|
      labels[index] = signup_date if index % 14 == 0
    end

    filename = "virality_signup_graph.png"
    create_graph("Line", title, subheading, graph_data, labels, filename)
  end

  # Graph for user signups per day
  def signup_graph
  	@page_title = "Signups Per day on "
    title = "Signups per day"
    subheading = "Users (" + User.count.to_s + " total)"

    @signups = User.find_by_sql( 'select YEAR(created_at) as year, MONTH(created_at) as month, DAY(created_at) as day, count(id) as sum from users group by DATE(created_at)' )
    graph_data = @signups.collect { |signup| signup.sum.to_i }

    labels = {}
    @signups.collect{ |signup| signup.day + "/" + signup.month + "/" + signup.year}.each_with_index do |signup_date, index|
      labels[index] = signup_date if index % 30 == 0
    end

    filename = "signup_graph.png"
    create_graph("Line", title, subheading, graph_data, labels, filename)
  end

  # Accumulative graph for user signups per day
  def signup_accumulator
    title = "Signup Accumulator"
    subheading = "Users (" + User.count.to_s + " total)"

    @user_count = 0
    @signups = User.find_by_sql( 'select YEAR(created_at) as year, MONTH(created_at) as month, DAY(created_at) as day, count(id) as sum from users group by DATE(created_at)' )
    graph_data = @signups.collect { |signup| @user_count += signup.sum.to_i }

    labels = {}
    @signups.collect{ |signup| signup.day + "/" + signup.month + "/" + signup.year}.each_with_index do |signup_date, index|
      labels[index] = signup_date if index % 30 == 0
    end

    filename = "signup_accumulator.png"
    create_graph("Bar", title, subheading, graph_data, labels, filename)
  end

  # Graph for beta user signups per day
  def beta_signup_graph
    title = "Beta Signups per day"
    last_fortnight = BetaUser.count( :conditions => [ "DATE(created_at) > ?", 2.weeks.ago.to_s(:db) ], :group => "DATE(created_at)")
    average = (last_fortnight.collect{ |lf| lf[1] }.sum.to_f / last_fortnight.size.to_f).round
    subheading = BetaUser.count.to_s + " beta users, avg. " + average.to_s + " signup(s) per day over the last fortnight"
    
    @signups = User.find_by_sql( 'select YEAR(created_at) as year, MONTH(created_at) as month, DAY(created_at) as day, count(id) as sum from beta_users group by DATE(created_at)' )
    graph_data = @signups.collect { |signup| signup.sum.to_i }

    labels = {}
    @signups.collect{ |signup| signup.day + "/" + signup.month + "/" + signup.year}.each_with_index do |signup_date, index|
      labels[index] = signup_date if index % 30 == 0
    end

    filename = "beta_signup_graph.png"
    create_graph("Line", title, subheading, graph_data, labels, filename)
  end

  # Accumulative graph for beta user signups per day
  def beta_signup_accumulator
    title = "Beta Signup Accumulator"
    subheading = "Users (" + User.count.to_s + " total)"

    @user_count = 0
    @signups = User.find_by_sql('select YEAR(created_at) as year, MONTH(created_at) as month, DAY(created_at) as day, count(id) as sum from beta_users group by DATE(created_at)')
    graph_data = @signups.collect { |signup| @user_count += signup.sum.to_i }

    labels = {}
    @signups.collect{ |signup| signup.day + "/" + signup.month + "/" + signup.year}.each_with_index do |signup_date, index|
      labels[index] = signup_date if index % 30 == 0
    end

    filename = "beta_signup_accumulator.png"
    create_graph("Bar", title, subheading, graph_data, labels, filename)
  end

  def messages_sent_per_day
    title = "Messages Sent Per Day"
    subheading = "Messages (" + Message.count.to_s + " total)"
    
    @messages = Message.find_by_sql( 'select YEAR(created_at) as year, MONTH(created_at) as month, DAY(created_at) as day, count(id) as sum from messages group by DATE(created_at)' )
    graph_data = @messages.collect { |message| message.sum.to_i }

    labels = {}
    @messages.collect{ |message| message.day + "/" + message.month + "/" + message.year}.each_with_index do |message_date, index|
      labels[index] = message_date if index % 14 == 0
    end

    filename = "messages_sent_per_day.png"
    create_graph("Line", title, subheading, graph_data, labels, filename)
  end

  # Any active user using any tool, see ticket #739
  def activity_per_user_per_day
    return

    title = "% Users Tool Usage Per Day"
    subheading = "What % of our users are using tools each day?"

    # # of tool_usages where type = tool (mines, crates, portals)
    # # of messages sent
    # # of forums posts
    # # of missions created/taken
    # # of portals created

    # Ok, look away now if copy/paste coding offends you....

    # missions created
    @missions_created = Mission.find_by_sql( 'select \'missions_created\' as name, user_id, DATE(created_at) as date from missions group by DATE(created_at), user_id' )

    # missions taken
    @missions_taken = Mission.find_by_sql( 'select \'missions_taken\' as name, user_id, DATE(created_at) as date from missionatings group by DATE(created_at), user_id' )

    # portals created
    @portals_created = Portal.find_by_sql( 'select \'portals_created\' as name, user_id, DATE(created_at) as date from portals group by DATE(created_at), user_id' )

    # other tool uses
    @tool_uses = ToolUse.find_by_sql( [ 'select \'tool_usage\' as name, user_id, DATE(created_at) as date from tool_uses where usage_type = ? group by DATE(created_at), user_id', 'tool' ] )

    # messages sent
    pmog_user = User.find_by_email('self@pmog.com')
    @messages_sent = Message.find_by_sql( [ 'select \'messages_sent\' as name, user_id, DATE(created_at) as date from messages where user_id != ? group by DATE(created_at), user_id', pmog_user.id ] )

    # forum posts
    @forum_posts = Post.find_by_sql( [ 'select \'forum_posts\' as name, user_id, DATE(created_at) as date from posts group by DATE(created_at), user_id' ] )

    @activity_data = {}
    [ @missions_created, @missions_taken, @portals_created, @tool_uses, @messages_sent, @forum_posts ].each do |stats|
      stats.each do |data|
        if @activity_data[ data.date ].nil?
          @activity_data[ data.date ] = {}
          @activity_data[ data.date ][ 'total' ] = 1
        else
          @activity_data[ data.date ][ 'total' ] += 1
        end

        if @activity_data[ data.date ][ 'user_ids' ].nil?
          @activity_data[ data.date ][ 'user_ids' ] = []
          @activity_data[ data.date ][ 'user_ids' ] << data.user_id
        else
          @activity_data[ data.date ][ 'user_ids' ] << data.user_id
        end
       end
    end

    @activity_data.each do |data|
      total_users = User.find_by_sql( [ 'select count(*) as sum from users where created_at <= ?', data[0] ] )
      if total_users[0].sum.to_i > 0
        percentage_active = ( (data[1]['user_ids'].uniq.size.to_f / total_users[0].sum.to_f) * 100).round
      else
        percentage_active = 0
      end
      @activity_data[ data[0] ][ 'percentage_active' ] = percentage_active
    end
    
    @activity_data = @activity_data.sort_by { |data| data[0] }

    graph_data = @activity_data.collect { |data| data[1][ 'percentage_active' ].to_i }

    labels = {}
    @activity_data.collect{ |data| data[0] }.each_with_index do |date, index|
      labels[index] = date if index % 14 == 0
    end

    filename = "connected_users_per_day.png"
    create_graph("Line", title, subheading, graph_data, labels, filename)
  end

  def extension_versions
    title = "Who's Using Which Extension Version?"
    filename = "extension_versions.png"

    g = Gruff::Pie.new('1280x1024')
    g.font = File.expand_path('fonts/Vera.ttf', RAILS_ROOT)
    g.legend_font_size = 8
    g.legend_box_size = 8
    g.title = title
          
    DailyActivity.find_by_sql( 'select extension_version, count(distinct(user_id)) as total_users from daily_activities group by extension_version').each do |ext|
      g.data(ext['extension_version'] + '\n' + ext['total_users'] + ' users', ext['total_users'].to_i)
    end

    send_data(g.to_blob, 
              :disposition => 'inline', 
              :type => 'image/png', 
              :filename => filename)
  end

  def extension_versions_yesterday
    title = "Who's Used Which Extension Version Yesterday?"
    filename = "extension_versions.png"

    g = Gruff::Pie.new('1280x1024')
    g.font = File.expand_path('fonts/Vera.ttf', RAILS_ROOT)
    g.legend_font_size = 8
    g.legend_box_size = 8
    g.title = title

    yesterday = Date.yesterday.to_s
    DailyActivity.find_by_sql( [ 'select extension_version, count(distinct(user_id)) as total_users from daily_activities where created_on = ? group by extension_version', yesterday ] ).each do |ext|
      g.data(ext['extension_version'] + '\n' + ext['total_users'] + ' users', ext['total_users'].to_i)
    end

    send_data(g.to_blob, 
              :disposition => 'inline', 
              :type => 'image/png', 
              :filename => filename)
  end

  def missions_taken_per_day
    title = "Daily Missionatings"
    subheading = "# of mission taken per day"
    
    @data = Mission.find_by_sql( [ 'select YEAR(created_at) as year, MONTH(created_at) as month, DAY(created_at) as day, count(user_id) as sum from missionatings WHERE DATE(created_at) > ? group by DATE(created_at)', 2.weeks.ago.to_s(:db) ] )
    graph_data = @data.collect { |data| data.sum.to_i }

    labels = {}
    @data.collect{ |data| data.day + "/" + data.month + "/" + data.year}.each_with_index do |date, index|
      labels[index] = date if index % 14 == 0
    end

    filename = "missions_taken_per_day.png"
    create_graph("Line", title, subheading, graph_data, labels, filename)
  end

  # number of missions taken divided by number of active users
  def missions_taken_per_user
    title = "Missions Taken Per User"
    subheading = "# mission taken / # active users"
    
    mission_data = {}
    @missions_taken = Mission.find_by_sql( [ 'select YEAR(created_at) as year, MONTH(created_at) as month, DAY(created_at) as day, DATE(created_at) as date, count(user_id) as sum from missionatings  where DATE(created_at) != DATE(?) AND created_at > ? group by DATE(created_at)', Date.today, 2.weeks.ago.to_s(:db) ] )
    @missions_taken.collect{ |mission| mission_data[mission.date] = mission.sum }

    active_data = {}
    @active_users = DailyActivity.find_by_sql( [ 'select YEAR(created_on) as year, MONTH(created_on) as month, DAY(created_on) as day, created_on as date, count(id) as sum, created_on from daily_activities where created_on != DATE(?) AND created_on > ? group by created_on', Date.today, 2.weeks.ago.to_s(:db) ] )
    @active_users.collect{ |active| active_data[active.date] = active.sum }

    graph_data = []
    mission_data.sort.each do |mission|
      graph_data << active_data[ mission[0] ].to_i / mission[1].to_i if active_data[ mission[0] ]
    end

    labels = {}
    @missions_taken.collect{ |data| data.day + "/" + data.month + "/" + data.year}.each_with_index do |date, index|
      labels[index] = date if index % 2 == 0
    end

    filename = "missions_taken_per_day.png"
    create_graph("Line", title, subheading, graph_data, labels, filename)
  end

  def missions_created_per_day
    title = "Mission Creation"
    subheading = "Missions created per day"
    
    @data = Mission.find_by_sql( 'select YEAR(created_at) as year, MONTH(created_at) as month, DAY(created_at) as day, count(id) as sum from missions group by DATE(created_at)' )
    graph_data = @data.collect { |data| data.sum.to_i }

    labels = {}
    @data.collect{ |data| data.day + "/" + data.month + "/" + data.year}.each_with_index do |date, index|
      labels[index] = date if index % 14 == 0
    end

    filename = "missions_created_per_day.png"
    create_graph("Line", title, subheading, graph_data, labels, filename)
  end

  # This is inaccurate since portals are deleted once their charges are expired.
  def portals_created_per_day
    title = "Portal Creation"
    subheading = "Portals created per day"
    
    @data = Portal.find_by_sql( 'select YEAR(created_at) as year, MONTH(created_at) as month, DAY(created_at) as day, count(id) as sum from portals group by DATE(created_at)' )
    graph_data = @data.collect { |data| data.sum.to_i }

    labels = {}
    @data.collect{ |data| data.day + "/" + data.month + "/" + data.year}.each_with_index do |date, index|
      labels[index] = date if index % 14 == 0
    end

    filename = "portals_created_per_day.png"
    create_graph("Line", title, subheading, graph_data, labels, filename)
  end

  # We take this data from the classpoints table, tool_uses, so it is more accurate
  def portals_taken_per_day
    title = "Portals Taken"
    subheading = "Portals taken per day"
    
    tool_id = Tool.cached_single('portals')
    @data = Portal.find_by_sql( [ 'select YEAR(created_at) as year, MONTH(created_at) as month, DAY(created_at) as day, count(user_id) as sum from tool_uses where tool_id = ? AND usage_type = ? group by DATE(created_at)', tool_id, 'tool' ] )
    graph_data = @data.collect { |data| data.sum.to_i }

    labels = {}
    @data.collect{ |data| data.day + "/" + data.month + "/" + data.year}.each_with_index do |date, index|
      labels[index] = date if index % 14 == 0
    end

    filename = "portals_taken_per_day.png"
    create_graph("Line", title, subheading, graph_data, labels, filename)
  end

  # Uses the +tool_uses+ table and combines armor points with mine points
  def mines_trigged_per_day
    title = "Mines Triggered"
    subheading = "Mines triggered per day"
    
    mine_id = Tool.cached_single('mines')
    armor_id = Tool.cached_single('armor')
    @data = Mine.find_by_sql( [ 'select YEAR(created_at) as year, MONTH(created_at) as month, DAY(created_at) as day, count(user_id) as sum from tool_uses where (tool_id = ? OR tool_id = ?) AND usage_type = ? group by DATE(created_at)', mine_id, armor_id, 'tool' ] )
    graph_data = @data.collect { |data| data.sum.to_i }

    labels = {}
    @data.collect{ |data| data.day + "/" + data.month + "/" + data.year}.each_with_index do |date, index|
      labels[index] = date if index % 14 == 0
    end

    filename = "mines_trigged_per_day.png"
    create_graph("Line", title, subheading, graph_data, labels, filename)
  end

  def crates_looted_per_day
    title = "Crates Looted"
    subheading = "Crates looted per day"
    
    tool_id = Tool.cached_single('crates')
    @data = Crate.find_by_sql( [ 'select YEAR(created_at) as year, MONTH(created_at) as month, DAY(created_at) as day, count(user_id) as sum from tool_uses where tool_id = ? AND usage_type = ? group by DATE(created_at)', tool_id, 'tool' ] )
    graph_data = @data.collect { |data| data.sum.to_i }

    labels = {}
    @data.collect{ |data| data.day + "/" + data.month + "/" + data.year}.each_with_index do |date, index|
      labels[index] = date if index % 14 == 0
    end

    filename = "crates_looted_per_day.png"
    create_graph("Line", title, subheading, graph_data, labels, filename)
  end

  # IM's sent, exluding those from the PMOG user notifying of badges awarded, etc.
  def messages_sent_per_day
    title = "Instant Messages"
    subheading = "Messages sent per day"

    pmog_user = User.find_by_email('self@pmog.com')
    @data = Message.find_by_sql( [ 'select YEAR(created_at) as year, MONTH(created_at) as month, DAY(created_at) as day, count(user_id) as sum from messages where user_id != ? group by DATE(created_at)', pmog_user.id ] )
    graph_data = @data.collect { |data| data.sum.to_i }

    labels = {}
    @data.collect{ |data| data.day + "/" + data.month + "/" + data.year}.each_with_index do |date, index|
      labels[index] = date if index % 14 == 0
    end

    filename = "messages_sent_per_day.png"
    create_graph("Line", title, subheading, graph_data, labels, filename)
  end

  def percentage_users_messaging_per_day
    title = "Instant Messages"
    subheading = "% Users sending messages per day"

    pmog_user = User.find_by_email('self@pmog.com')
    @data = Message.find_by_sql( [ 'select YEAR(created_at) as year, MONTH(created_at) as month, DAY(created_at) as day, count(distinct(user_id)) as sum, created_at from messages where user_id != ? group by DATE(created_at)', pmog_user.id ] )

    graph_data = @data.collect { |data| 
      total_users = User.find_by_sql( [ 'select count(*) as sum from users where created_at <= ?', data.created_at ] )
      ( (data.sum.to_f / total_users[0].sum.to_f) * 100).round
    }

    labels = {}
    @data.collect{ |data| data.day + "/" + data.month + "/" + data.year}.each_with_index do |date, index|
      labels[index] = date if index % 14 == 0
    end

    filename = "percentage_users_messaging_per_day.png"
    create_graph("Line", title, subheading, graph_data, labels, filename)
  end

  def forum_posts_per_day
    title = "Forum Posts"
    subheading = "Posts created per day"

    @data = Post.find_by_sql( [ 'select YEAR(created_at) as year, MONTH(created_at) as month, DAY(created_at) as day, count(user_id) as sum from posts group by DATE(created_at)' ] )
    graph_data = @data.collect { |data| data.sum.to_i }

    labels = {}
    @data.collect{ |data| data.day + "/" + data.month + "/" + data.year}.each_with_index do |date, index|
      labels[index] = date if index % 14 == 0
    end

    filename = "forum_posts_per_day.png"
    create_graph("Line", title, subheading, graph_data, labels, filename)
  end
  
  def total_datapoints_earned_surfing_per_day
    return #disabled

    title = "Total Datapoints Earned By Surfing"
    subheading = "Total datapoints earned by all active users per day, in the last fortnight"

    @data = Transaction.find_by_sql( [ 'select YEAR(created_at) as year, MONTH(created_at) as month, DAY(created_at) as day, count(id) as sum from transactions WHERE comment LIKE ? AND created_at > ? group by DATE(created_at)', '%track_domain%', 2.weeks.ago.to_s(:db) ] )
    graph_data = @data.collect { |data| data.sum.to_i }

    labels = {}
    @data.collect{ |data| data.day + "/" + data.month + "/" + data.year}.each_with_index do |date, index|
      labels[index] = date if index % 14 == 0
    end

    filename = "total_datapoints_earned_surfing_per_day.png"
    create_graph("Line", title, subheading, graph_data, labels, filename)
  end
  
  def average_datapoints_per_user_earned_surfing_per_day
    return #disabled

    title = "Average Datapoints Earned Per User"
    subheading = "Average Datapoints earned by browsing per active user, in the last fortnight"

    @data = Transaction.find_by_sql( [ 'select YEAR(created_at) as year, MONTH(created_at) as month, DAY(created_at) as day, count(id) as sum from transactions WHERE comment LIKE ? AND created_at > ? group by DATE(created_at)', '%track_domain%', 2.weeks.ago.to_s(:db) ] )
    @active_users = DailyActivity.find_by_sql( ACTIVE_USERS_SQL )
    
    graph_data = @data.collect { |data| data.sum.to_i / @active_users.at(@data.index(data)).sum.to_i }

    labels = {}
    @data.collect{ |data| data.day + "/" + data.month + "/" + data.year}.each_with_index do |date, index|
      labels[index] = date if index % 14 == 0
    end

    filename = "average_datapoints_earned_surfing_per_day.png"
    create_graph("Line", title, subheading, graph_data, labels, filename)
  end

  def average_acquaintances_per_user
    title = "Average Acquaintances Per User"
    subheading = "Includes Allies, Rivals and Acquaintances"

    # Created a model to contain this data.
    @data = UserAcquaintanceStats.find(:all, :group => "created_at")
    
    # Get the average acquaintances per user.
    graph_data = @data.collect {|data| data.acquaintance_count / data.user_count}
    
    labels = {}
    @data.collect {|data| data.created_at.strftime("%d/%m/%y")}.each_with_index do |created_at, index|
      labels[index] = created_at if index % 14 == 0
    end

    filename = "average_acquaintances_per_user.png"
    create_graph("Line", title, subheading, graph_data, labels, filename)
  end

  # % of players who have taken a mission
  def users_mission_taking
    all_users_count = User.count
    
    users_with_taken_count = ActiveRecord::Base.connection.select_all("SELECT COUNT(users.user_id) AS user_count FROM (SELECT * FROM missionatings GROUP BY user_id) AS users")[0]["user_count"].to_i
    users_with_taken_prct = ((users_with_taken_count.to_f / all_users_count.to_f) * 100).round
    
    users_without_taken_count = (all_users_count - users_with_taken_count)
    users_without_taken_prct = ((users_without_taken_count.to_f / all_users_count.to_f) * 100).round
    
    g = Gruff::Pie.new('1280x1024')
    g.font = File.expand_path('fonts/Vera.ttf', RAILS_ROOT)
    g.legend_font_size = 8
    g.legend_box_size = 8
    
    g.title = "How many players have taken missions?"    
    g.data('Have taken\n' + users_with_taken_count.to_s + " users (" + users_with_taken_prct.to_s + "%)" , users_with_taken_count, "green")
    g.data("Haven't taken\n" + users_without_taken_count.to_s + " users (" + users_without_taken_prct.to_s + "%)", users_without_taken_count, "red")
    
    send_data(g.to_blob, :disposition => 'inline', :type => 'image/png', :filename => "users_taken_missions.png")
  end
  
  def users_with_generated_missions
    all_users_count = User.count
    
    users_with_missions_count = Mission.count_by_sql("SELECT COUNT(distinct user_id) FROM missions")
    users_with_missions_prct = ((users_with_missions_count.to_f / all_users_count.to_f) * 100).round
    
    users_without_missions_count = (all_users_count - users_with_missions_count)
    users_without_missions_prct = ((users_without_missions_count.to_f / all_users_count.to_f) * 100).round
    
    
    g = Gruff::Pie.new('1280x1024')
    g.font = File.expand_path('fonts/Vera.ttf', RAILS_ROOT)
    g.legend_font_size = 8
    g.legend_box_size = 8
    
    g.title = "Player Mission Generation"    
    g.data('Have\n' + users_with_missions_count.to_s + " users (" + users_with_missions_prct.to_s + "%)" , users_with_missions_count, "green")
    g.data("Have not\n" + users_without_missions_count.to_s + " users (" + users_without_missions_prct.to_s + "%)", users_without_missions_count, "red")
    
    send_data(g.to_blob, :disposition => 'inline', :type => 'image/png', :filename => "users_with_missions.png")
  end
  
  def view
  	@page_title = "Dynamic Stats for "
    @charts = ["signups", "invites", "generated_missions", "taken_missions", "signups_accumulator", "concurrency", "top_ten_tlds", "levels", "portals_taken_by_active_users", "browser_stats", 'crates_stashed_this_week', 'crates_stashed_last_week', 'crates_stashed_all_time', 'missions_completed_this_week', 'missions_completed_last_week', 'missions_completed_all_time', 'mines_triggered_this_week', 'mines_triggered_last_week', 'mines_triggered_all_time', 'crates_looted_this_week', 'crates_looted_last_week', 'crates_looted_all_time', 'messages_sent_this_week', 'messages_sent_last_week', 'messages_sent_all_time', 'summons_sent_all_time', 'summons_confirmed_sent_all_time' ]
    params[:chart] = "signups" if params[:chart].nil?
    @graph = open_flash_chart_object('100%','100%', '/stats/' + params[:chart], false, '/', true) 
  end
  
  def signups
    @total_signups = Stat.calculate_new_signups_per_day
    
    g = Graph.new
    g.title( 'Signups', '{color: #7E97A6; font-size: 20; text-align: center}' )
    
    g.set_data(@total_signups.collect { |signup| signup.sum.to_i })
    g.line_hollow(2, 4, '#164166', 'Total Signups', 10)
    g.set_y_max(@total_signups.collect { |signup| signup.sum.to_i }.max)
    g.set_x_legend( 'Timeline', 12, '#164166' )
    g.set_y_legend( 'Player Signups', 12, '#164166' )
    tmp = []
    @total_signups.collect{ |signup| signup.month + "/" + signup.day + "/" + signup.year}.each_with_index do |signup_date, index|
       tmp << signup_date
    end
    g.set_x_labels(tmp)
    g.set_x_label_style(10, '#164166', 2, 3, '#818D9D' )
    g.set_y_label_steps(10)

    render :text => g.render
  end
  
  def invites
    @signups = User.find_by_sql( ["SELECT YEAR(users.created_at) as year, 
                                         MONTH(users.created_at) as month,
                                         DAY(users.created_at) as day, 
                                         COUNT(users.id) as sum from users, beta_keys 
                                            WHERE users.beta_key_id = beta_keys.id 
                                            AND beta_keys.user_id != '4630774e-93bb-11dc-bd1d-00163e4ab66d' 
                                            AND users.beta_key_id is not null 
                                            AND users.created_at >= ? 
                                            GROUP BY DATE(users.created_at)", 60.days.ago.to_s(:db)] )
    g = Graph.new
    g.title( 'Invites', '{color: #7E97A6; font-size: 20; text-align: center}' )
    
    g.set_data(@signups.collect { |signup| signup.sum.to_i })
    g.line_dot( 2, 4, '#818D9D', 'Invitee Signups', 10 )
    g.set_y_max(@signups.collect { |signup| signup.sum.to_i }.max)
    
    g.set_x_legend( 'Timeline', 12, '#164166' )
    g.set_y_legend( 'Invites', 12, '#164166' )
    tmp = []
    @signups.collect{ |signup| signup.month + "/" + signup.day + "/" + signup.year}.each_with_index do |signup_date, index|
       tmp << signup_date
    end
    g.set_x_labels(tmp)
    g.set_x_label_style(10, '#164166', 2, 3, '#818D9D' )
    g.set_y_label_steps(10)

    render :text => g.render
  end
  def signups_accumulator
    @user_count = 0
    @signups = User.find_by_sql( 'select YEAR(created_at) as year, MONTH(created_at) as month, DAY(created_at) as day, count(id) as sum from users group by DATE(created_at)' )

    bar_blue = Bar3d.new(85, '#3334AD')
    bar_blue.key('Total Players', 10)

    bar_blue.data << @signups.collect { |signup| @user_count += signup.sum.to_i }
    
    g = Graph.new
    g.title("Player Signup Accumulator", "{font-size:20px; color: #FFFFFF; margin: 5px;background-color: #505050; padding:5px; padding-left: 20px; padding-right: 20px;}")
    g.set_bg_color("#ffffff")
    g.data_sets << bar_blue

    g.set_x_axis_3d(12)
    g.set_x_axis_color('#999999', '#fDB5C7')
    g.set_y_axis_color('#ffffff', '#fDB5C7')
    
    labels = []
    @signups.collect{ |signup| signup.day + "/" + signup.month + "/" + signup.year}.each_with_index do |signup_date, index|
      labels[index] = signup_date
    end
    g.set_x_labels(labels)
    g.set_x_label_style(10, '#164166', 2, 3 )
    g.set_y_max(@signups.collect { |signup| signup.sum.to_i }.max)
    g.set_y_label_steps(5)
    g.set_y_legend("Players", 12, "#736AFF")
    render :text => g.render
  end

  def generated_missions
    all_users_count = User.count
    
    users_with_missions_count = Mission.count_by_sql("SELECT COUNT(distinct user_id) FROM missions")
    users_with_missions_prct = ((users_with_missions_count.to_f / all_users_count.to_f) * 100).round
    
    users_without_missions_count = (all_users_count - users_with_missions_count)
    users_without_missions_prct = ((users_without_missions_count.to_f / all_users_count.to_f) * 100).round
    
    data = [users_with_missions_prct, users_without_missions_prct]
    
    g = Graph.new
      g.pie(60, '#505050', '{font-size: 12px; color: #404040;}')
      g.pie_values(data, ["Have Generated", "Haven't Generated"])
      g.pie_slice_colors(%w(#d01fc3 #356aa0))
      g.set_tool_tip("#val#%")
      g.title("Mission Generation Stats", '{font-size:18px; color: #d01f3c}' )
      render :text => g.render
  end
  
  def taken_missions
    all_users_count = User.count
    
    users_with_taken_count = ActiveRecord::Base.connection.select_all("SELECT COUNT(users.user_id) AS user_count FROM (SELECT * FROM missionatings GROUP BY user_id) AS users")[0]["user_count"].to_i
    users_with_taken_prct = ((users_with_taken_count.to_f / all_users_count.to_f) * 100).round
    
    users_without_taken_count = (all_users_count - users_with_taken_count)
    users_without_taken_prct = ((users_without_taken_count.to_f / all_users_count.to_f) * 100).round
    
    data = [users_with_taken_prct, users_without_taken_prct]
    
    g = Graph.new
    g.pie(60, '#505050', '{font-size: 12px; color: #404040;}')
    g.pie_values(data, ["Have Taken", "Haven't Taken"])
    g.pie_slice_colors(%w(#d01fc3 #356aa0))
    g.set_tool_tip("#val#%")
    g.title("Mission Taking Stats", '{font-size:18px; color: #d01f3c}' )
    render :text => g.render
  end

  def concurrent_users
    return # DEPRECATED
    title = "Concurrent Users"
    subheading = "Maximum Hourly Concurrent Users Per Day, Over The Last Fortnight"

    @data = HourlyActivity.concurrent_users

    graph_data = @data.collect{ |d| d.total.to_i }
    labels = {}
    @data.collect{ |data| [ data.created_on, data.hour ] }.each_with_index do |row, index|
      if index % 24 == 0
        labels[index] = row[0].to_date.strftime("%d/%m/%y")
      end
    end

    filename = "concurrent_users.png"
    create_graph("Bar", title, subheading, graph_data, labels, filename)
  end

  def levels
    @data = User.find( :all, :select => 'current_level, count(*) as total', :group => 'current_level' )
    bar_blue = Bar3d.new(85, '#3334AD')
    bar_blue.key('Number of Users', 10)
    bar_blue.data << @data.collect{ |d| d.total.to_i }
    
    g = Graph.new
    g.title("User Levels", "{font-size:20px; color: #FFFFFF; margin: 5px;background-color: #505050; padding:5px; padding-left: 20px; padding-right: 20px;}")
    g.set_bg_color("#ffffff")
    g.data_sets << bar_blue

    g.set_x_axis_3d(12)
    g.set_x_axis_color('#999999', '#fDB5C7')
    g.set_y_axis_color('#ffffff', '#fDB5C7')

    labels = []
    @data.collect{ |data| [ data.current_level ] }.each_with_index do |row, index|
      labels[index] = row[0].to_s
    end
    g.set_x_labels(labels)
    g.set_x_label_style(10, '#164166', 2, 3 )
    g.set_y_max( @data.collect{ |d| d.total.to_i }.max )
    g.set_y_label_steps(5)
    g.set_y_legend("User Levels", 12, "#736AFF")
    render :text => g.render
  end

  def browser_stats
    data = BrowserStat.find( :all, :select => 'count(id) as total, os, browser_name, browser_version', :group => 'os, browser_name, browser_version', :order => 'total DESC' )
    bar_blue = Bar3d.new(85, '#3334AD')
    bar_blue.key('Browser Stats', 10)
    
    pie_totals = []
    pie_labels = []
    data.collect{ |d| 
      pie_totals << d.total
      pie_labels << d.os + '/' + d.browser_name + '/' + d.browser_version
    }
    

    g = Graph.new
    g.pie(60, '#505050', '{font-size: 12px; color: #404040;}')
    g.pie_values(pie_totals, pie_labels)
    g.pie_slice_colors(%w(#d01fc3 #356aa0))
    g.set_tool_tip("#val#%")
    g.title("Browser Stats", '{font-size:18px; color: #d01f3c}' )
    render :text => g.render
  end
  
  def gender_breakdown
    title = "PMOG Gender Breakdown"
    filename = "gender_breakdown.png"

    g = Gruff::Pie.new('1280x1024')
    g.font = File.expand_path('fonts/Vera.ttf', RAILS_ROOT)
    g.legend_font_size = 8
    g.legend_box_size = 8
    g.title = title

    genders = { 'm' => 0, 'f' => 0 }
    User.find(:all).each do |user|
      next if user.gender.empty? or user.gender.nil?
      genders[ user.gender.downcase ] += 1
    end

    genders.each do |gender|
      gender[0] == 'm' ? label = "Male (#{genders[ 'm' ]})" : label = "Female (#{genders[ 'f' ]})"
      g.data( label, gender[1] )
    end

    send_data(g.to_blob, 
              :disposition => 'inline', 
              :type => 'image/png', 
              :filename => filename)
  end

  # What percentage of signups are passively active in their first month
  # Note that we define active as pinging our message API
  def initial_passive_activity
    title = "Initial Passive Activity"
    subheading = "% users connected in the first month of signup"

    labels = {}
    graph_data = []

    # An array of the last 6 months
    previous_months = []
    6.times do |i|
      previous_months << (i+1).months.ago # +1 to exlude the current month
    end

    previous_months.reverse.each_with_index do |start_date, index|
      end_date = start_date.next_month

      @signups = User.find( :all, :select => 'id, created_at', :conditions => [ 'YEAR(created_at) = ? AND MONTH(created_at) = ?', start_date.year, start_date.month ] )
      user_ids = @signups.collect{ |u| u.id }.uniq

      @retention = DailyActivity.find( :all, :select => 'id', :conditions => [ 'user_id IN (?) AND created_on BETWEEN ? AND ?', user_ids, start_date, end_date ], :group => :user_id )

      begin
        graph_data << ( (@retention.size.to_f / @signups.size.to_f ) * 100 ).round
      rescue
        graph_data << 0
      end
      
      labels[index] = start_date.to_s + '\n' + end_date.to_s
    end

    filename = "initial_passive_activity.png"
    create_graph("Line", title, subheading, graph_data, labels, filename)
  end
  
  # From Justin: "day by day, of the people who signed up for pmog 40 days before this date,
  # X % were connected to PMOG within the last 10 days"
  def user_retention
    g = Gruff::Pie.new('1280x1024')
    g.font = File.expand_path('fonts/Vera.ttf', RAILS_ROOT)
    g.legend_font_size = 8
    g.legend_box_size = 8

    # +date+ is the point from which we look back for signups and forwards for connectivity
    date = params[:date].nil? ? 10.days.ago : params[:date].to_date

    # +signup_window+ is the date we look back to for signups
    signup_window = params[:signup_window].nil? ? 40.days.ago(date) : params[:signup_window].to_date

    # +connectivity_window+ is the date we look forward to, for signs of connectivity
    connectivity_window = params[:connectivity_window].nil? ? 10.days.since(date) : params[:connectivity_window].to_date

    # Now get the users who signed up in that period
    @signups = User.find( :all, :select => 'id, created_at', :conditions => [ 'created_at BETWEEN ? AND ?', signup_window, date ] )
    user_ids = @signups.collect{ |u| u.id }.uniq

    # And the signs of activity from those people
    @retention = DailyActivity.find( :all, :select => 'id', :conditions => [ 'user_id IN (?) AND created_on BETWEEN ? AND ?', user_ids, date, connectivity_window ], :group => :user_id )

    g.title = "Signups From #{signup_window} To #{date} Connected From #{date} Until #{connectivity_window}"
    g.title_font_size = 16

    begin
      graph_data = ( (@retention.size.to_f / @signups.size.to_f ) * 100 ).round
    rescue
      graph_data = 0
    end

    g.data("% #{graph_data} Active", graph_data)
    g.data("% #{(100 - graph_data)} Inactive", (100 - graph_data))

    filename = "user_retention.png"
    send_data(g.to_blob, 
              :disposition => 'inline', 
              :type => 'image/png', 
              :filename => filename)
  end

  # Disabled, the daily_domains table is too big for this now.
  def top_ten_tlds
    return
    
    bar_blue = Bar3d.new(85, '#3334AD')
    bar_blue.key('Top TLDs', 10)

    # Each row in the daily domains table represents a unique user hitting a tld. So this query gives us a list
    # of the top tlds ordered by the total number of users who have visited that tld since pmog has been active
    @tlds = DailyDomain.execute( 'SELECT count(*) AS total, location_id FROM daily_domains GROUP BY  location_id ORDER BY total DESC LIMIT 100' )

    index = 0
    labels = []
    @tlds.each do |tld|
      bar_blue.data << tld[0].to_i
      labels[index] = Location.find(tld[1]).url
      index += 1
    end
    
    g = Graph.new
    g.title("Top TLDs", "{font-size:20px; color: #FFFFFF; margin: 5px;background-color: #505050; padding:5px; padding-left: 20px; padding-right: 20px;}")
    g.set_bg_color("#ffffff")
    g.data_sets << bar_blue

    g.set_x_axis_3d(12)
    g.set_x_axis_color('#999999', '#fDB5C7')
    g.set_y_axis_color('#ffffff', '#fDB5C7')
    
    g.set_x_labels(labels)
    g.set_x_label_style(10, '#164166', 2, 3 )
    g.set_y_max( (bar_blue.data.max.to_i + 1000) )
    g.set_y_label_steps(5)
    g.set_y_legend("Players", 12, "#736AFF")
    render :text => g.render
  end

  # Disabled, as it'll kill the site at some point.
  def portals_taken_by_active_users
    return

    @portals_taken = Portal.find_by_sql( [ 'select YEAR(created_at) as year, MONTH(created_at) as month, DAY(created_at) as day, DATE(created_at) as date, count(user_id) as sum from tool_uses where tool_id = ? AND usage_type = ? group by DATE(created_at)', Tool.cached_single('portals'), 'tool' ] )
    @active_users = DailyActivity.find_by_sql( [ 'select YEAR(created_on) as year, MONTH(created_on) as month, DAY(created_on) as day, created_on as date, count(id) as sum, created_on from daily_activities where created_on != DATE(?) group by created_on', Date.today ] )

    active_data = {}
    @active_users.reverse.each do |active|
      active_data[active.date] = active.sum.to_i
    end

    portal_data = {}
    @portals_taken.reverse.each do |portal|
      portal_data[portal.date] = portal.sum.to_i
    end

    data_1 = LineHollow.new(2,5,'#CC3399')
    data_1.key("Active Users",10)
    
    data_2 = LineHollow.new(2,5,'#9933CC')
    data_2.key('Portals Taken', 10)

    active_data.sort.each do |active|
      data_1.add_data_tip(active[1], "Active Users")
    end

    portal_data.sort.each do |portal|
      data_2.add_data_tip(portal[1], "Portals")
    end

    g = Graph.new
    g.title("Portals Taken & Active Users", "{font-size: 20px; color: #736AFF}")
    g.data_sets << data_1
    g.data_sets << data_2

    g.set_tool_tip('#x_label# [#val#]<br>#tip#')
    
    dates = (active_data.keys + portal_data.keys).sort.uniq
    g.set_x_labels(dates)
    g.set_x_label_style(10, '#164166', 2, 3 )

    g.set_y_max(10000)
    g.set_y_label_steps(4)
    g.set_y_legend("Portals Taken & Active Users", 12, "#736AFF")

    render :text => g.render
  end

  def crates_stashed_this_week
    crates = Crate.stashed_this_week

    g = Graph.new
    g.title( "Crates Stashed This Week", '{color: #7E97A6; font-size: 20; text-align: center}' )
    g.set_data(crates.collect{ |c| c.count.to_i })
    g.line_dot( 2, 4, '#818D9D', 'Crates stashed', 10 )
    g.set_x_legend( 'Date stashed', 12, '#164166' )
    g.set_y_legend( 'Total stashes', 12, '#164166' )
    g.set_x_labels(crates.collect{ |c| c.date })
    g.set_x_label_style(10, '#164166', 2, 3, '#818D9D' )
    g.set_y_label_steps(10)
    g.set_y_max(crates.collect{ |c| c.count.to_i }.max)
    render :text => g.render
  end

  def crates_stashed_last_week
    crates = Crate.stashed_last_week

    g = Graph.new
    g.title( "Crates Stashed Last Week", '{color: #7E97A6; font-size: 20; text-align: center}' )
    g.set_data(crates.collect{ |c| c.count.to_i })
    g.line_dot( 2, 4, '#818D9D', 'Crates stashed', 10 )
    g.set_x_legend( 'Date stashed', 12, '#164166' )
    g.set_y_legend( 'Total stashes', 12, '#164166' )
    g.set_x_labels(crates.collect{ |c| c.date })
    g.set_x_label_style(10, '#164166', 2, 3, '#818D9D' )
    g.set_y_label_steps(10)
    g.set_y_max(crates.collect{ |c| c.count.to_i }.max)
    render :text => g.render
  end

  def crates_stashed_all_time
    crates = Crate.stashed_all_time

    g = Graph.new
    g.title( "Crates Stashed All Time", '{color: #7E97A6; font-size: 20; text-align: center}' )
    g.set_data(crates.collect{ |c| c.count.to_i })
    g.line_dot( 2, 4, '#818D9D', 'Crates stashed', 10 )
    g.set_x_legend( 'Date stashed', 12, '#164166' )
    g.set_y_legend( 'Total stashes', 12, '#164166' )
    g.set_x_labels(crates.collect{ |c| c.date })
    g.set_x_label_style(10, '#164166', 2, 3, '#818D9D' )
    g.set_y_label_steps(10)
    g.set_y_max(crates.collect{ |c| c.count.to_i }.max)
    render :text => g.render
  end

  def missions_completed_this_week
    completions = Mission.completed_this_week

    g = Graph.new
    g.title( "Missions Completed This Week", '{color: #7E97A6; font-size: 20; text-align: center}' )
    g.set_data(completions.collect{ |c| c.count.to_i })
    g.line_dot( 2, 4, '#818D9D', 'Missions completed', 10 )
    g.set_x_legend( 'Date completed', 12, '#164166' )
    g.set_y_legend( 'Total completions', 12, '#164166' )
    g.set_x_labels(completions.collect{ |c| c.date })
    g.set_x_label_style(10, '#164166', 2, 3, '#818D9D' )
    g.set_y_label_steps(10)
    g.set_y_max(completions.collect{ |c| c.count.to_i }.max)
    render :text => g.render
  end

  def missions_completed_last_week
    completions = Mission.completed_last_week

    g = Graph.new
    g.title( "Missions Completed Last Week", '{color: #7E97A6; font-size: 20; text-align: center}' )
    g.set_data(completions.collect{ |c| c.count.to_i })
    g.line_dot( 2, 4, '#818D9D', 'Missions completed', 10 )
    g.set_x_legend( 'Date completed', 12, '#164166' )
    g.set_y_legend( 'Total completions', 12, '#164166' )
    g.set_x_labels(completions.collect{ |c| c.date })
    g.set_x_label_style(10, '#164166', 2, 3, '#818D9D' )
    g.set_y_label_steps(10)
    g.set_y_max(completions.collect{ |c| c.count.to_i }.max)
    render :text => g.render
  end

  def missions_completed_all_time
    completions = Mission.completed_all_time

    g = Graph.new
    g.title( "Missions Completed All Time", '{color: #7E97A6; font-size: 20; text-align: center}' )
    g.set_data(completions.collect{ |c| c.count.to_i })
    g.line_dot( 2, 4, '#818D9D', 'Missions completed', 10 )
    g.set_x_legend( 'Date completed', 12, '#164166' )
    g.set_y_legend( 'Total completions', 12, '#164166' )
    g.set_x_labels(completions.collect{ |c| c.date })
    g.set_x_label_style(10, '#164166', 2, 3, '#818D9D' )
    g.set_y_label_steps(10)
    g.set_y_max(completions.collect{ |c| c.count.to_i }.max)
    render :text => g.render
  end

  def mines_triggered_this_week
    data = Mine.triggered_this_week

    g = Graph.new
    g.title( "Mines Triggered This Week", '{color: #7E97A6; font-size: 20; text-align: center}' )
    g.set_data(data.collect{ |c| c.count.to_i })
    g.line_dot( 2, 4, '#818D9D', 'Mines triggered', 10 )
    g.set_x_legend( 'Date triggered', 12, '#164166' )
    g.set_y_legend( 'Total triggers', 12, '#164166' )
    g.set_x_labels(data.collect{ |c| c.date })
    g.set_x_label_style(10, '#164166', 2, 3, '#818D9D' )
    g.set_y_label_steps(10)
    g.set_y_max(data.collect{ |c| c.count.to_i }.max)
    render :text => g.render
  end

  def mines_triggered_last_week
    data = Mine.triggered_last_week

    g = Graph.new
    g.title( "Mines Triggered Last Week", '{color: #7E97A6; font-size: 20; text-align: center}' )
    g.set_data(data.collect{ |c| c.count.to_i })
    g.line_dot( 2, 4, '#818D9D', 'Mines triggered', 10 )
    g.set_x_legend( 'Date triggered', 12, '#164166' )
    g.set_y_legend( 'Total triggers', 12, '#164166' )
    g.set_x_labels(data.collect{ |c| c.date })
    g.set_x_label_style(10, '#164166', 2, 3, '#818D9D' )
    g.set_y_label_steps(10)
    g.set_y_max(data.collect{ |c| c.count.to_i }.max)
    render :text => g.render
  end

  def mines_triggered_all_time
    data = Stat.calculate_mines_triggered_all_time

    g = Graph.new
    g.title( "Mines Triggered All Time", '{color: #7E97A6; font-size: 20; text-align: center}' )
    g.set_data(data.collect{ |c| c.count.to_i })
    g.line_dot( 2, 4, '#818D9D', 'Mines triggered', 10 )
    g.set_x_legend( 'Date triggered', 12, '#164166' )
    g.set_y_legend( 'Total triggers', 12, '#164166' )
    g.set_x_labels(data.collect{ |c| c.date })
    g.set_x_label_style(10, '#164166', 2, 3, '#818D9D' )
    g.set_y_label_steps(10)
    g.set_y_max(data.collect{ |c| c.count.to_i }.max)
    render :text => g.render
  end

  def crates_looted_this_week
    data = Crate.looted_this_week

    g = Graph.new
    g.title( "Crates Looted This Week", '{color: #7E97A6; font-size: 20; text-align: center}' )
    g.set_data(data.collect{ |c| c.count.to_i })
    g.line_dot( 2, 4, '#818D9D', 'Crates looted', 10 )
    g.set_x_legend( 'Date looted', 12, '#164166' )
    g.set_y_legend( 'Total lootings', 12, '#164166' )
    g.set_x_labels(data.collect{ |c| c.date })
    g.set_x_label_style(10, '#164166', 2, 3, '#818D9D' )
    g.set_y_label_steps(10)
    g.set_y_max(data.collect{ |c| c.count.to_i }.max)
    render :text => g.render
  end

  def crates_looted_last_week
    data = Crate.looted_last_week

    g = Graph.new
    g.title( "Crates Looted Last Week", '{color: #7E97A6; font-size: 20; text-align: center}' )
    g.set_data(data.collect{ |c| c.count.to_i })
    g.line_dot( 2, 4, '#818D9D', 'Crates looted', 10 )
    g.set_x_legend( 'Date looted', 12, '#164166' )
    g.set_y_legend( 'Total lootings', 12, '#164166' )
    g.set_x_labels(data.collect{ |c| c.date })
    g.set_x_label_style(10, '#164166', 2, 3, '#818D9D' )
    g.set_y_label_steps(10)
    g.set_y_max(data.collect{ |c| c.count.to_i }.max)
    render :text => g.render
  end

  def crates_looted_all_time
    data = Crate.looted_all_time
    
    g = Graph.new
    g.title( "Crates Looted All Time", '{color: #7E97A6; font-size: 20; text-align: center}' )
    g.set_data(data.collect{ |c| c.count.to_i })
    g.line_dot( 2, 4, '#818D9D', 'Crates looted', 10 )
    g.set_x_legend( 'Date looted', 12, '#164166' )
    g.set_y_legend( 'Total lootings', 12, '#164166' )
    g.set_x_labels(data.collect{ |c| c.date })
    g.set_x_label_style(10, '#164166', 2, 3, '#818D9D' )
    g.set_y_label_steps(10)
    g.set_y_max(data.collect{ |c| c.count.to_i }.max)
    render :text => g.render
  end

  def messages_sent_this_week
    data = Stat.calculate_number_of_pmails_sent_this_week

    g = Graph.new
    g.title( "Messages Sent This Week", '{color: #7E97A6; font-size: 20; text-align: center}' )
    g.set_data(data.collect{ |c| c.count.to_i })
    g.line_dot( 2, 4, '#818D9D', 'Messages sent', 10 )
    g.set_x_legend( 'Date sent', 12, '#164166' )
    g.set_y_legend( 'Total messages', 12, '#164166' )
    g.set_x_labels(data.collect{ |c| c.date })
    g.set_x_label_style(10, '#164166', 2, 3, '#818D9D' )
    g.set_y_label_steps(10)
    g.set_y_max(data.collect{ |c| c.count.to_i }.max)
    render :text => g.render
  end

  def messages_sent_last_week
    data = Stat.calculate_number_of_pmails_sent_last_week

    g = Graph.new
    g.title( "Messages Sent Last Week", '{color: #7E97A6; font-size: 20; text-align: center}' )
    g.set_data(data.collect{ |c| c.count.to_i })
    g.line_dot( 2, 4, '#818D9D', 'Messages sent', 10 )
    g.set_x_legend( 'Date sent', 12, '#164166' )
    g.set_y_legend( 'Total messages', 12, '#164166' )
    g.set_x_labels(data.collect{ |c| c.date })
    g.set_x_label_style(10, '#164166', 2, 3, '#818D9D' )
    g.set_y_label_steps(10)
    g.set_y_max(data.collect{ |c| c.count.to_i }.max)
    render :text => g.render
  end

  def messages_sent_all_time
    data = Stat.calculate_number_of_pmails_sent_all_time

    g = Graph.new
    g.title( "Messages Sent All Time", '{color: #7E97A6; font-size: 20; text-align: center}' )
    g.set_data(data.collect{ |c| c.count.to_i })
    g.line_dot( 2, 4, '#818D9D', 'Messages sent', 10 )
    g.set_x_legend( 'Date sent', 12, '#164166' )
    g.set_y_legend( 'Total messages', 12, '#164166' )
    g.set_x_labels(data.collect{ |c| c.date })
    g.set_x_label_style(10, '#164166', 2, 3, '#818D9D' )
    g.set_y_label_steps(10)
    g.set_y_max(data.collect{ |c| c.count.to_i }.max)
    render :text => g.render
  end

  def summons_sent_all_time
    data = Message.summons_sent_all_time

    g = Graph.new
    g.title( "Summons Sent All Time", '{color: #7E97A6; font-size: 20; text-align: center}' )
    g.set_data(data.collect{ |c| c.count.to_i })
    g.line_dot( 2, 4, '#818D9D', 'Summons sent', 10 )
    g.set_x_legend( 'Date sent', 12, '#164166' )
    g.set_y_legend( 'Total summons set', 12, '#164166' )
    g.set_x_labels(data.collect{ |c| c.date })
    g.set_x_label_style(10, '#164166', 2, 3, '#818D9D' )
    g.set_y_label_steps(10)
    g.set_y_max(data.collect{ |c| c.count.to_i }.max)
    render :text => g.render
  end

  def summons_confirmed_sent_all_time
    data = Message.summons_confirmed_all_time

    g = Graph.new
    g.title( "Summons Accepted All Time", '{color: #7E97A6; font-size: 20; text-align: center}' )
    g.set_data(data.collect{ |c| c.count.to_i })
    g.line_dot( 2, 4, '#818D9D', 'Summons accepted', 10 )
    g.set_x_legend( 'Date sent', 12, '#164166' )
    g.set_y_legend( 'Total summons accepted', 12, '#164166' )
    g.set_x_labels(data.collect{ |c| c.date })
    g.set_x_label_style(10, '#164166', 2, 3, '#818D9D' )
    g.set_y_label_steps(10)
    g.set_y_max(data.collect{ |c| c.count.to_i }.max)
    render :text => g.render
  end

  def connected_users_per_day
    @connected_users = Stat.calculate_connected_users_per_day
    
    g = Graph.new
    g.title( 'Connected Users Per Day', '{color: #7E97A6; font-size: 20; text-align: center}' )
    
    g.set_data(@connected_users.collect{ |user| user.count.to_i })
    g.set_y_max(@connected_users.collect{ |user| user.count.to_i}.max)
    g.line_hollow(2, 4, '#164166', 'Connected Users', 10)
    g.set_x_legend( 'Timeline', 12, '#164166' )
    g.set_y_legend( 'Active Users', 12, '#164166' )
    tmp = []
    @connected_users.collect{ |user| user.month + "/" + user.day + "/" + user.year}.each_with_index do |user_date, index|
       tmp << user_date
    end
    g.set_x_labels(tmp)
    g.set_x_label_style(10, '#164166', 2, 3, '#818D9D' )
    g.set_y_label_steps(10)

    render :text => g.render
  end

  def connected_users_per_hour
    @connected_users = Stat.calculate_connected_users_per_hour

    g = Graph.new
    g.title( 'Connected Users Per Hour', '{color: #7E97A6; font-size: 20; text-align: center}' )
    
    g.set_data(@connected_users.collect{ |user| user.sum.to_i })
    g.set_y_max(@connected_users.collect{ |user| user.sum.to_i}.max)
    g.line_hollow(2, 4, '#164166', 'Active Users', 10)
    g.set_x_legend( 'Timeline', 12, '#164166' )
    g.set_y_legend( 'Connected Users', 12, '#164166' )
    tmp = []
    @connected_users.collect{ |data| [ data.created_on, data.hour ] }.each_with_index do |row, index|
      tmp[index] = row[0].to_date.strftime("%d/%m/%y") + ' ' + row[1].to_s + ":00"
    end
    g.set_x_labels(tmp)
    g.set_x_label_style(10, '#164166', 2, 3, '#818D9D' )
    g.set_y_label_steps(10)

    render :text => g.render
  end
  def number_of_user_ratings_per_day
    @ratings = Stat.calculate_number_of_user_ratings_per_day
    
    g = Graph.new
    g.title( 'User Ratings Per Day', '{color: #7E97A6; font-size: 20; text-align: center}' )
    
    g.set_data(@ratings.collect { |r| r.count.to_i })
    g.line_hollow(2, 4, '#164166', 'Number of Ratings', 10)
    g.set_y_max(@ratings.collect { |r| r.count.to_i }.max)
    g.set_x_legend( 'Timeline', 12, '#164166' )
    g.set_y_legend( 'Ratings', 12, '#164166' )
    tmp = []
    @ratings.collect{ |r| r.month + "/" + r.day + "/" + r.year}.each_with_index do |r_date, index|
       tmp << r_date
    end
    g.set_x_labels(tmp)
    g.set_x_label_style(10, '#164166', 2, 3, '#818D9D' )
    g.set_y_label_steps(10)

    render :text => g.render
  end

  def number_of_mission_ratings_per_day
    @ratings = Stat.calculate_number_of_mission_ratings_per_day
    
    g = Graph.new
    g.title( 'Mission Ratings Per Day', '{color: #7E97A6; font-size: 20; text-align: center}' )
    
    g.set_data(@ratings.collect { |r| r.count.to_i })
    g.line_hollow(2, 4, '#164166', 'Number of Ratings', 10)
    g.set_y_max(@ratings.collect { |r| r.count.to_i }.max)
    g.set_x_legend( 'Timeline', 12, '#164166' )
    g.set_y_legend( 'Ratings', 12, '#164166' )
    tmp = []
    @ratings.collect{ |r| r.month + "/" + r.day + "/" + r.year}.each_with_index do |r_date, index|
       tmp << r_date
    end
    g.set_x_labels(tmp)
    g.set_x_label_style(10, '#164166', 2, 3, '#818D9D' )
    g.set_y_label_steps(10)

    render :text => g.render
  end

  def number_of_players_sending_pmail_per_day
  	@page_title = "Number of Players Sending PMails Per Day on "
    @pmails = Stat.calculate_number_of_players_sending_pmail_per_day
    
    g = Graph.new
    g.title( 'Players Sending PMails Per Day', '{color: #7E97A6; font-size: 20; text-align: center}' )
    
    g.set_data(@pmails.collect { |p| p.count.to_i })
    g.line_hollow(2, 4, '#164166', 'Number of PMails', 10)
    g.set_y_max(@pmails.collect { |p| p.count.to_i }.max)
    g.set_x_legend( 'Timeline', 12, '#164166' )
    g.set_y_legend( 'PMails', 12, '#164166' )
    tmp = []
    @pmails.collect{ |p| p.month + "/" + p.day + "/" + p.year}.each_with_index do |p_date, index|
       tmp << p_date
    end
    g.set_x_labels(tmp)
    g.set_x_label_style(10, '#164166', 2, 3, '#818D9D' )
    g.set_y_label_steps(10)

    render :text => g.render
  end

  def percentage_connected_users_per_day
    @connected_users, @percentages = Stat.calculate_percentage_connected_users_per_day
    
    g = Graph.new
    g.title( '% Active Users Per Day', '{color: #7E97A6; font-size: 20; text-align: center}' )
    
    g.set_data(@percentages)
    g.set_y_max(@percentages.max)
    g.line_hollow(2, 4, '#164166', 'Active Users', 10)
    g.set_x_legend( 'Timeline', 12, '#164166' )
    g.set_y_legend( '% Active Users', 12, '#164166' )
    tmp = []
    @connected_users.collect{ |user| user.month + "/" + user.day + "/" + user.year}.each_with_index do |user_date, index|
       tmp << user_date
    end
    g.set_x_labels(tmp)
    g.set_x_label_style(10, '#164166', 2, 3, '#818D9D' )
    g.set_y_label_steps(10)

    render :text => g.render
  end

  def active_users_per_day
    @active_users = Stat.calculate_active_users

    g = Graph.new
    g.title( 'Active Users Per Day (tools deployed, missions created, forum postings)', '{color: #7E97A6; font-size: 20; text-align: center}' )
    g.set_data(@active_users.collect{ |u| u.count })
    g.set_y_max(@active_users.collect{ |u| u.count.to_i }.max)
    g.line_hollow(2, 4, '#164166', 'Active Users', 10)
    g.set_x_legend( 'Timeline', 12, '#164166' )
    g.set_y_legend( 'Active Users', 12, '#164166' )
    g.set_x_labels(@active_users.collect{ |u| u.date })
    g.set_x_label_style(10, '#164166', 2, 3, '#818D9D' )
    g.set_y_label_steps(10)

    render :text => g.render
  end

  def reactive_users_per_day
    @reactive_users = Stat.calculate_reactive_users

    g = Graph.new
    g.title( 'Reactive Users Per Day (tools looted/triggered/etc, missions stumbled upon)', '{color: #7E97A6; font-size: 20; text-align: center}' )
    g.set_data(@reactive_users.collect{ |u| u.count })
    g.set_y_max(@reactive_users.collect{ |u| u.count.to_i }.max)
    g.line_hollow(2, 4, '#164166', 'Active Users', 10)
    g.set_x_legend( 'Timeline', 12, '#164166' )
    g.set_y_legend( 'Reactive Users', 12, '#164166' )
    g.set_x_labels(@reactive_users.collect{ |u| u.date })
    g.set_x_label_style(10, '#164166', 2, 3, '#818D9D' )
    g.set_y_label_steps(10)

    render :text => g.render
  end

  def connected_active_reactive_per_day
  	@page_title = "Connected, Active, Reactive Per Day on "
    @users = Stat.calculate_connected_active_reactive_per_day

    data_1 = LineHollow.new(2,5,'#CC3399')
    data_1.key("Connected Users",10)

    data_2 = LineHollow.new(2,5,'#164166')
    data_2.key("Active Users",10)
    
    data_3 = LineHollow.new(2,5,'#00FF00')
    data_3.key('Reactive Users', 10)

    @users[:connected].sort_by{ |u| u[0] }.each do |u|
      data_1.add_data_tip(u[1], "Connected Users")
    end

    @users[:active].sort_by{ |u| u[0]}.each do |u|
      data_2.add_data_tip(u[1], "Active Users")
    end

    @users[:reactive].sort_by{ |u| u[0]}.each do |u|
      data_3.add_data_tip(u[1], "Reactive Users")
    end

    g = Graph.new
    g.title( 'Connect, Active & Reactive Users Per Day', '{color: #7E97A6; font-size: 20; text-align: center}' )
    g.data_sets << data_1
    g.data_sets << data_2
    g.data_sets << data_3

    g.set_tool_tip('#x_label#<br>#tip# [#val#]')
    
    g.set_x_labels(@users[:dates])
    g.set_x_label_style(10, '#164166', 2, 3 )

    g.set_y_max(@users[:max])
    g.set_y_label_steps(4)
    g.set_x_legend( 'Timeline', 12, '#164166' )
    g.set_y_legend( 'Connected, Active, Reactive Users', 12, '#164166' )

    render :text => g.render
  end

  def number_of_users_drawing_portals_per_day
    @portals_users = Stat.calculate_number_of_users_deploying_tool_per_day('portals')

    g = Graph.new
    g.title( 'Number of Users drawing Portals, per day', '{color: #7E97A6; font-size: 20; text-align: center}' )
    g.set_data(@portals_users.collect{ |p| p.count })
    g.set_y_max(@portals_users.collect{ |p| p.count.to_i }.max)
    g.line_hollow(2, 4, '#164166', 'Active Users', 10)
    g.set_x_legend( 'Timeline', 12, '#164166' )
    g.set_y_legend( 'Number of Users', 12, '#164166' )
    g.set_x_labels(@portals_users.collect{ |u| u.date })
    g.set_x_label_style(10, '#164166', 2, 3, '#818D9D' )
    g.set_y_label_steps(10)

    render :text => g.render
  end

  def number_of_portals_drawn_per_day
    @portals = Stat.calculate_number_of_tools_deployed_per_day('portals')

    g = Graph.new
    g.title( 'Number of Portals drawn, per day', '{color: #7E97A6; font-size: 20; text-align: center}' )
    g.set_data(@portals.collect{ |p| p.count })
    g.set_y_max(@portals.collect{ |p| p.count.to_i }.max)
    g.line_hollow(2, 4, '#164166', 'Portals', 10)
    g.set_x_legend( 'Timeline', 12, '#164166' )
    g.set_y_legend( 'Number of Portals', 12, '#164166' )
    g.set_x_labels(@portals.collect{ |u| u.date })
    g.set_x_label_style(10, '#164166', 2, 3, '#818D9D' )
    g.set_y_label_steps(10)

    render :text => g.render
  end

  def number_of_users_laying_mines_per_day
    @mines_users = Stat.calculate_number_of_users_deploying_tool_per_day('mines')

    g = Graph.new
    g.title( 'Attack - Number of Users laying Mines, per day', '{color: #7E97A6; font-size: 20; text-align: center}' )
    g.set_data(@mines_users.collect{ |m| m.count })
    g.set_y_max(@mines_users.collect{ |m| m.count.to_i }.max)
    g.line_hollow(2, 4, '#164166', 'Mines', 10)
    g.set_x_legend( 'Timeline', 12, '#164166' )
    g.set_y_legend( 'Number of Users', 12, '#164166' )
    g.set_x_labels(@mines_users.collect{ |u| u.date })
    g.set_x_label_style(10, '#164166', 2, 3, '#818D9D' )
    g.set_y_label_steps(10)

    render :text => g.render
  end

  def number_of_mines_deployed_per_day
    @mines = Stat.calculate_number_of_tools_deployed_per_day('mines')

    g = Graph.new
    g.title( 'Attack - Number of Mines deployed, per day', '{color: #7E97A6; font-size: 20; text-align: center}' )
    g.set_data(@mines.collect{ |m| m.count })
    g.set_y_max(@mines.collect{ |m| m.count.to_i }.max)
    g.line_hollow(2, 4, '#164166', 'Mines', 10)
    g.set_x_legend( 'Timeline', 12, '#164166' )
    g.set_y_legend( 'Number of Mines', 12, '#164166' )
    g.set_x_labels(@mines.collect{ |u| u.date })
    g.set_x_label_style(10, '#164166', 2, 3, '#818D9D' )
    g.set_y_label_steps(10)

    render :text => g.render
  end

  def number_of_players_taking_portals_per_day
    @portals = Stat.calculate_number_of_players_taking_portals_per_day

    g = Graph.new
    g.title( 'Number of Players taking Portals, per day', '{color: #7E97A6; font-size: 20; text-align: center}' )
    g.set_data(@portals.collect{ |p| p.count })
    g.set_y_max(@portals.collect{ |p| p.count.to_i }.max)
    g.line_hollow(2, 4, '#164166', 'Portals', 10)
    g.set_x_legend( 'Timeline', 12, '#164166' )
    g.set_y_legend( 'Number of Portals', 12, '#164166' )
    g.set_x_labels(@portals.collect{ |p| p.date })
    g.set_x_label_style(10, '#164166', 2, 3, '#818D9D' )
    g.set_y_label_steps(10)

    render :text => g.render
  end

  def number_of_players_laying_giftcards_per_day
    @giftcards = Stat.calculate_number_of_players_laying_giftcards_per_day

    g = Graph.new
    g.title( 'Awsm - Number of Players laying DP Cards, per day', '{color: #7E97A6; font-size: 20; text-align: center}' )
    g.set_data(@giftcards.collect{ |gc| gc.count })
    g.set_y_max(@giftcards.collect{ |gc| gc.count.to_i }.max)
    g.line_hollow(2, 4, '#164166', 'DP Cards', 10)
    g.set_x_legend( 'Timeline', 12, '#164166' )
    g.set_y_legend( 'Number of DP Cards', 12, '#164166' )
    g.set_x_labels(@giftcards.collect{ |gc| gc.date })
    g.set_x_label_style(10, '#164166', 2, 3, '#818D9D' )
    g.set_y_label_steps(10)

    render :text => g.render
  end

  def number_of_giftcards_deployed_per_day
    @giftcards= Stat.calculate_number_of_tools_deployed_per_day('giftcards')

    g = Graph.new
    g.title( 'Awsm - Number of DP Cards deployed, per day', '{color: #7E97A6; font-size: 20; text-align: center}' )
    g.set_data(@giftcards.collect{ |gc| gc.count })
    g.set_y_max(@giftcards.collect{ |gc| gc.count.to_i }.max)
    g.line_hollow(2, 4, '#164166', 'DP Cards', 10)
    g.set_x_legend( 'Timeline', 12, '#164166' )
    g.set_y_legend( 'Number of Users', 12, '#164166' )
    g.set_x_labels(@giftcards.collect{ |gc| gc.date })
    g.set_x_label_style(10, '#164166', 2, 3, '#818D9D' )
    g.set_y_label_steps(10)

    render :text => g.render
  end

  def number_of_players_completing_missions_per_day
    @missions = Stat.calculate_number_of_players_completing_missions_per_day

    g = Graph.new
    g.title( 'Number of Players completing Missions, per day', '{color: #7E97A6; font-size: 20; text-align: center}' )
    g.set_data(@missions.collect{ |m| m.count })
    g.set_y_max(@missions.collect{ |m| m.count.to_i }.max)
    g.line_hollow(2, 4, '#164166', 'Missions', 10)
    g.set_x_legend( 'Timeline', 12, '#164166' )
    g.set_y_legend( 'Number of Missions', 12, '#164166' )
    g.set_x_labels(@missions.collect{ |m| m.date })
    g.set_x_label_style(10, '#164166', 2, 3, '#818D9D' )
    g.set_y_label_steps(10)

    render :text => g.render
  end

  def number_of_users_stashing_crates_per_day
    @crates_users = Stat.calculate_number_of_users_deploying_tool_per_day('crates')

    g = Graph.new
    g.title( 'Number of Users stashing Crates, per day', '{color: #7E97A6; font-size: 20; text-align: center}' )
    g.set_data(@crates_users.collect{ |c| c.count })
    g.set_y_max(@crates_users.collect{ |c| c.count.to_i }.max)
    g.line_hollow(2, 4, '#164166', 'Crates', 10)
    g.set_x_legend( 'Timeline', 12, '#164166' )
    g.set_y_legend( 'Number of Users', 12, '#164166' )
    g.set_x_labels(@crates_users.collect{ |c| c.date })
    g.set_x_label_style(10, '#164166', 2, 3, '#818D9D' )
    g.set_y_label_steps(10)

    render :text => g.render
  end

  def number_of_crates_stashed_per_day
    @crates_users = Stat.calculate_number_of_tools_deployed_per_day('crates')

    g = Graph.new
    g.title( 'Number of Crates stashed, per day', '{color: #7E97A6; font-size: 20; text-align: center}' )
    g.set_data(@crates_users.collect{ |c| c.count })
    g.set_y_max(@crates_users.collect{ |c| c.count.to_i }.max)
    g.line_hollow(2, 4, '#164166', 'Crates', 10)
    g.set_x_legend( 'Timeline', 12, '#164166' )
    g.set_y_legend( 'Number of Crates', 12, '#164166' )
    g.set_x_labels(@crates_users.collect{ |c| c.date })
    g.set_x_label_style(10, '#164166', 2, 3, '#818D9D' )
    g.set_y_label_steps(10)

    render :text => g.render
  end

  def number_of_players_attaching_st_nicks_per_day
    @st_nicks = Stat.calculate_number_of_users_deploying_tool_per_day('st_nicks')

    g = Graph.new
    g.title( 'Number of Users attaching St Nicks, per day', '{color: #7E97A6; font-size: 20; text-align: center}' )
    g.set_data(@st_nicks.collect{ |s| s.count })
    g.set_y_max(@st_nicks.collect{ |s| s.count.to_i }.max)
    g.line_hollow(2, 4, '#164166', 'St Nicks', 10)
    g.set_x_legend( 'Timeline', 12, '#164166' )
    g.set_y_legend( 'Number of Users', 12, '#164166' )
    g.set_x_labels(@st_nicks.collect{ |s| s.date })
    g.set_x_label_style(10, '#164166', 2, 3, '#818D9D' )
    g.set_y_label_steps(10)

    render :text => g.render
  end
  
  def number_of_st_nicks_attached_per_day
    @st_nicks = Stat.calculate_number_of_tools_deployed_per_day('st_nicks')

    g = Graph.new
    g.title( 'Number of St Nicks attached, per day', '{color: #7E97A6; font-size: 20; text-align: center}' )
    g.set_data(@st_nicks.collect{ |s| s.count })
    g.set_y_max(@st_nicks.collect{ |s| s.count.to_i }.max)
    g.line_hollow(2, 4, '#164166', 'St Nicks', 10)
    g.set_x_legend( 'Timeline', 12, '#164166' )
    g.set_y_legend( 'Number of St Nicks', 12, '#164166' )
    g.set_x_labels(@st_nicks.collect{ |s| s.date })
    g.set_x_label_style(10, '#164166', 2, 3, '#818D9D' )
    g.set_y_label_steps(10)

    render :text => g.render
  end
  
  def number_of_players_creating_missions_per_day
    @missions = Stat.calculate_number_of_players_creating_missions_per_day

    g = Graph.new
    g.title( 'Number of Users creating Missions, per day', '{color: #7E97A6; font-size: 20; text-align: center}' )
    g.set_data(@missions.collect{ |m| m.count })
    g.set_y_max(@missions.collect{ |m| m.count.to_i }.max)
    g.line_hollow(2, 4, '#164166', 'Missions', 10)
    g.set_x_legend( 'Timeline', 12, '#164166' )
    g.set_y_legend( 'Number of Users', 12, '#164166' )
    g.set_x_labels(@missions.collect{ |m| m.date })
    g.set_x_label_style(10, '#164166', 2, 3, '#818D9D' )
    g.set_y_label_steps(10)

    render :text => g.render
  end

  def number_of_missions_created_per_day
    @missions = Stat.calculate_number_of_missions_created_per_day

    g = Graph.new
    g.title( 'Number of Missions created, per day', '{color: #7E97A6; font-size: 20; text-align: center}' )
    g.set_data(@missions.collect{ |m| m.count })
    g.set_y_max(@missions.collect{ |m| m.count.to_i }.max)
    g.line_hollow(2, 4, '#164166', 'Missions', 10)
    g.set_x_legend( 'Timeline', 12, '#164166' )
    g.set_y_legend( 'Number of Missions', 12, '#164166' )
    g.set_x_labels(@missions.collect{ |m| m.date })
    g.set_x_label_style(10, '#164166', 2, 3, '#818D9D' )
    g.set_y_label_steps(10)

    render :text => g.render
  end

  def number_of_players_deploying_grenades_per_day
    @grenades = Stat.calculate_number_of_users_deploying_tool_per_day('grenades', 'perp_id')

    g = Graph.new
    g.title( 'Number of Users deploying Grenades, per day', '{color: #7E97A6; font-size: 20; text-align: center}' )
    g.set_data(@grenades.collect{ |w| w.count })
    g.set_y_max(@grenades.collect{ |w| w.count.to_i }.max)
    g.line_hollow(2, 4, '#164166', 'Grenades', 10)
    g.set_x_legend( 'Timeline', 12, '#164166' )
    g.set_y_legend( 'Number of Users', 12, '#164166' )
    g.set_x_labels(@grenades.collect{ |w| w.date })
    g.set_x_label_style(10, '#164166', 2, 3, '#818D9D' )
    g.set_y_label_steps(10)

    render :text => g.render
  end

  def number_of_grenades_deployed_per_day
    @grenades = Stat.calculate_number_of_tools_deployed_per_day('grenades')

    g = Graph.new
    g.title( 'Number of Grenades deployed, per day', '{color: #7E97A6; font-size: 20; text-align: center}' )
    g.set_data(@grenades.collect{ |w| w.count })
    g.set_y_max(@grenades.collect{ |w| w.count.to_i }.max)
    g.line_hollow(2, 4, '#164166', 'Grenades', 10)
    g.set_x_legend( 'Timeline', 12, '#164166' )
    g.set_y_legend( 'Number of Users', 12, '#164166' )
    g.set_x_labels(@grenades.collect{ |w| w.date })
    g.set_x_label_style(10, '#164166', 2, 3, '#818D9D' )
    g.set_y_label_steps(10)

    render :text => g.render
  end

  def number_of_players_deploying_watchdogs_per_day
    @watchdogs = Stat.calculate_number_of_users_deploying_tool_per_day('watchdogs')

    g = Graph.new
    g.title( 'Number of Users deploying Watchdogs, per day', '{color: #7E97A6; font-size: 20; text-align: center}' )
    g.set_data(@watchdogs.collect{ |w| w.count })
    g.set_y_max(@watchdogs.collect{ |w| w.count.to_i }.max)
    g.line_hollow(2, 4, '#164166', 'Watchdogs', 10)
    g.set_x_legend( 'Timeline', 12, '#164166' )
    g.set_y_legend( 'Number of Users', 12, '#164166' )
    g.set_x_labels(@watchdogs.collect{ |w| w.date })
    g.set_x_label_style(10, '#164166', 2, 3, '#818D9D' )
    g.set_y_label_steps(10)

    render :text => g.render
  end

  def number_of_watchdogs_deployed_per_day
    @watchdogs = Stat.calculate_number_of_tools_deployed_per_day('watchdogs')

    g = Graph.new
    g.title( 'Number of Watchdogs deployed, per day', '{color: #7E97A6; font-size: 20; text-align: center}' )
    g.set_data(@watchdogs.collect{ |w| w.count })
    g.set_y_max(@watchdogs.collect{ |w| w.count.to_i }.max)
    g.line_hollow(2, 4, '#164166', 'Watchdogs', 10)
    g.set_x_legend( 'Timeline', 12, '#164166' )
    g.set_y_legend( 'Number of Users', 12, '#164166' )
    g.set_x_labels(@watchdogs.collect{ |w| w.date })
    g.set_x_label_style(10, '#164166', 2, 3, '#818D9D' )
    g.set_y_label_steps(10)

    render :text => g.render
  end

  protected
  def create_graph(graph_type, title, subheading, graph_data, labels, filename)
    graph_type == "Line" ? g = Gruff::Line.new(1600) : g = Gruff::StackedBar.new(1600)

    g.font = File.expand_path('fonts/Vera.ttf', RAILS_ROOT)
    g.legend_font_size = 16
    g.marker_font_size = 14
    g.title = title
    g.labels = labels
    g.replace_colors( [ 'yellow', 'blue' ] )

    g.data(subheading, graph_data)

    send_data(g.to_blob, 
              :disposition => 'inline', 
              :type => 'image/png', 
              :filename => filename)
  end
end
