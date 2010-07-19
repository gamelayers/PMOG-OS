class SuttreeController < ApplicationController
  before_filter :login_required
  #before_filter :authenticate
  permit 'site_admin'
  helper :sparklines
  
  def index
    render :nothing => true
    return
    
  	@page_title = "Empowered Systems Overview for "
    @status = {}
    @status[:top] = `uptime`.split[9..11]
    @status[:uptime] = `uptime`.split[2..3].join(' ').chop
    @status[:estimated_hits] = `wc -l #{RAILS_ROOT}/log/#{RAILS_ENV}.log`.split[0]
    @status[:cache] = CACHE.stats rescue nil

    # Disabled - not relevant, takes too long to load too.
    #@status[:referrers] = `awk '{print $11}' "/var/log/nginx/pmog.access.log" | grep -vE "(^"-"$|/www.pmog|assets.*.pmog|ext.pmog.com|/pmog)" | sort | uniq -c | sort -rn | head -10`.split

    # Sessions are in memcached now
    #sessions = Cron.execute( "select count(*) as total from fast_sessions" )
    #sessions.each do |s|
    #  @status[:sessions] = s[0].to_i
    #end
    
    questions = Cron.execute( "show status like 'Questions'" )
    questions.each do |q|
      @status[:questions] = q[1].to_i
    end

    uptime = Cron.execute( "show status like 'Uptime'" )
    uptime.each do |u|
      @status[:mysql_uptime] = u[1].to_i
    end
    @status[:qps] = (@status[:questions] / @status[:mysql_uptime])
    
    @locations_data = User.get_cache( 'locations_data', :ttl => 2.days ) do
      res = Cron.execute("show table status like 'locations'")
      row = res.fetch_hash
      [ row['Rows'], row['Avg_row_length'], row['Data_length'], row['Index_length'] ]
    end
    
    @daily_domains_data = User.get_cache( 'daily_domains_data', :ttl => 2.days ) do
      res = Cron.execute("show table status like '#{DailyDomain.table_name}'")
      row = res.fetch_hash
      [ row['Rows'], row['Avg_row_length'], row['Data_length'], row['Index_length'] ]
    end
    
    @daily_activities_data = User.get_cache( 'daily_activities_data', :ttl => 2.days ) do
      res = Cron.execute("show table status like 'daily_activities'")
      row = res.fetch_hash
      [ row['Rows'], row['Avg_row_length'], row['Data_length'], row['Index_length'] ]
    end

    @daily_log_ins_data = User.get_cache( 'daily_log_ins_data', :ttl => 2.days ) do
      res = Cron.execute("show table status like 'daily_log_ins'")
      row = res.fetch_hash
      [ row['Rows'], row['Avg_row_length'], row['Data_length'], row['Index_length'] ]
    end

    @events_data = User.get_cache( 'events_data', :ttl => 2.days ) do
      res = Cron.execute("show table status like 'events'")
      row = res.fetch_hash
      [ row['Rows'], row['Avg_row_length'], row['Data_length'], row['Index_length'] ]
    end

    @inventories_data = User.get_cache( 'inventories_data', :ttl => 2.days ) do
      res = Cron.execute("show table status like 'inventories'")
      row = res.fetch_hash
      [ row['Rows'], row['Avg_row_length'], row['Data_length'], row['Index_length'] ]
    end
    
    @hourly_activities_data = User.get_cache( 'hourly_activites_data', :ttl => 2.days ) do
      res = Cron.execute("show table status like 'hourly_activities'")
      row = res.fetch_hash
      [ row['Rows'], row['Avg_row_length'], row['Data_length'], row['Index_length'] ]
    end

    @tool_uses_data = User.get_cache( 'tool_uses_data', :ttl => 2.days ) do
      res = Cron.execute("show table status like 'tool_uses'")
      row = res.fetch_hash
      [ row['Rows'], row['Avg_row_length'], row['Data_length'], row['Index_length'] ]
    end
    
    @messages_data = User.get_cache( 'messages_data', :ttl => 2.days ) do
      res = Cron.execute("show table status like 'messages'")
      row = res.fetch_hash
      [ row['Rows'], row['Avg_row_length'], row['Data_length'], row['Index_length'] ]
    end

    @concurrency = User.get_cache( 'suttree_concurrency', :ttl => 2.days ) do
      Stat.calculate_connected_users_per_hour.collect{ |c| c.sum.to_i }
    end

    @daily_concurrency = User.get_cache( 'suttree_daily_concurrency', :ttl => 2.days ) do
      data = Stat.calculate_connected_users_per_day.collect{ |c| c.count.to_i }
      data[-180..data.size]
    end
    
    @tool_uses = User.get_cache( 'suttree_tool_uses', :ttl => 2.days ) do
      User.slave_setup do
        User.find_by_sql( [ 'select created_at, count(id) as sum from tool_uses where tool_uses.usage_type = \'tool\' and tool_uses.created_at > ? group by DATE(created_at)', 6.months.ago.to_s(:db) ] ).collect{ |t| t.sum.to_i }
      end
    end
    
    @signups = User.get_cache( 'suttree_signups', :ttl => 2.days ) do
      User.slave_setup do
        User.find_by_sql( [ 'select YEAR(created_at) as year, MONTH(created_at) as month, DAY(created_at) as day, count(id) as sum from users where created_at > ? group by DATE(created_at)', 6.months.ago.to_s(:db) ] ).collect{ |u| u.sum.to_i }
      end
    end
    
    @messages = User.get_cache( 'suttree_messages', :ttl => 2.days ) do
      Message.slave_setup do
        Message.find_by_sql( [ 'select YEAR(created_at) as year, MONTH(created_at) as month, DAY(created_at) as day, count(id) as sum from messages where created_at > ? group by DATE(created_at)', 6.months.ago.to_s(:db) ] ).collect{ |m| m.sum.to_i }
      end
    end
    
    @posts = User.get_cache( 'suttree_posts', :ttl => 2.days ) do
      User.slave_setup do
        User.find_by_sql( [ 'select YEAR(created_at) as year, MONTH(created_at) as month, DAY(created_at) as day, count(user_id) as sum from posts where created_at > ? group by DATE(created_at)', 6.months.ago.to_s(:db) ] ).collect{ |p| p.sum.to_i }
      end
    end

    @jobs = Bj.table.job.paginate( :all,
                                   :order => 'state DESC, priority DESC',
                                   :conditions => "state in ('pending', 'running')",
                                   :page => params[:page],
                                   :per_page => 100 )
  end

  def monitor
    @page_title = 'CCTV for your CPU on '
  end

  def c3pu
    @page_title = 'Great stats kid, that was one in a million | '
  end

  def rpm
    @page_title = 'Really Potty Mouthed on '
  end

  # Added to override/disable the clientperf measurements for methods in this controller, 
  # as they can be very slow and not indicative of the site performance - duncan 05/02/09
  def add_clientperf_to(response)
    response
  end
end
