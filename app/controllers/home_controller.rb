class HomeController < ApplicationController
  helper :missions
  session :off, :except => [ :index, :home, :toolbarlanding, :install ]
  caches_action :robots
  caches_action :index => { :ttl => 1.week, :if => Proc.new { |c| ! c.logged_in? } }
  before_filter :get_most_recent_events, :only => [:index, :toolbarlanding]
  before_filter :create_brain_buster, :only => [:toolbarlanding, :index]

  def index
    #set_xpingback_header
    @page_title = 'Welcome to '

    if logged_in?
      # Clear this from the session when a user visits their profile.
      #session[:new_user] = false

      # EDIT THE NUMBER OF POSTS HERE
      @latest_posts = Post.caches(:latest, :withs => [current_user, 4], :ttl => 1.hour)

      nsfw = false

      threshold = current_user.preferences.get('The Nethernet Mission Content Quality Threshold').value.to_i rescue 4

      # EDIT THE NUMBER OF MISSIONS HERE
      @missions = Mission.find(:all, :limit => 4, :conditions => ["nsfw = ? AND average_rating >= ?", nsfw, threshold], :order => "missions.created_at DESC")

      #Pulling from Blog RSS Feeds:
      #@community_news = RssReader.get_pmog_news_stream
      #@special_happenings = RssReader.get_special_happenings

      # leaderboards stuff:
      @leaders = []

      @classes = PmogClass.find :all

      @classes.each do |pmog_class|
        @leaders[pmog_class.id]= DailyClasspoints.leaders_for(pmog_class.id, 1).first rescue nil
      end

      render :action => :home
    else
      @user = User.new
      render :action => :welcome
    end
  end

  def toolbarlanding
    redirect_to "/acquaintances/#{current_user.login}" if logged_in?

    @user = User.new
    @page_title = "Welcome to "
  end

  # We want different robots.txt files for dev.pmog.com and everywhere else
  def robots
    if request.env[ 'HTTP_HOST' ] == 'dev.pmog.com' || request.env[ 'HTTP_HOST' ] == 'dev.thenethernet.com'
      render :partial => 'robots_txt_staging.txt.erb'
    else
      render :partial => 'robots_txt_production.txt.erb'
    end
  end

  # The old bud.com/news
  def deprecated_news
    redirect_to('http://news.pmog.com') and return
  end

  # The old bud.com/news atom feed
  def deprecated_news_feed_atom
    redirect_to('http://news.pmog.com/feed/atom/') and return
  end

  # The old bud.com/news xml feed
  def deprecated_index_xml
    redirect_to('http://news.pmog.com/feed/') and return
  end

  # The v1 extension tracker is redirected here
  def deprecated_track
    render :nothing => true and return
  end

  # The v1 extension stats call is redirected here
  def deprecated_firefox_stats
    render :text => 'Visit www.pmog.com to\nupgrade\n0\n0' and return
  end

  private
  # Called from a before_filter to set the events to show by default in the events section
  # of the home page when a user is logged in. We used to default to showing your
  # acquaintace news feed  on the home page, but that's very expensive to generate, so it's
  # disabled for now - duncan 24/01/09
  def set_event_param
    if logged_in? and params[:event_type].nil?
      params[:event_type] = 'you'
      #if current_user.buddies.cached_accepted.empty?
      #  params[:event_type] = 'you'
      #else
      #  params[:event_type] = 'acquaintances'
      #end
    end
  end

  def set_mission_param
    if logged_in? and params[:mission_type].nil?
      if current_user.buddies.cached_contacts.empty?
        params[:mission_type] = 'latest'
      else
        params[:mission_type] = 'acquaintances'
      end
    end
  end

  def get_event_data(params)
    case params[:event_type]
      when 'acquaintances' then current_user.events.cached_acquaintances_news_feed(10)
      when 'all'           then current_user.events.cached_news_feed(10)
      when 'you'           then current_user.events.cached_your_news_feed(10)
      else                      current_user.events.cached_your_news_feed(10) # default to the current user
     end
  end

  def get_mission_data(params)
    case params[:mission_type]
      when 'acquaintances' then current_user.missions.acquaintances_latest_missions(10)
      when 'latest'        then Mission.caches( :latest, :with => 10 )
    end
  end
  # This is called before the index and toolbarlanding actions are displayed. Thus we don't need to
  # Gather events within those actions.
  def get_most_recent_events
    @events = Event.find(:all, :joins => "LEFT JOIN users ON events.user_id=users.id", :select => "events.*, users.login AS user_login", :order => 'created_at DESC', :limit => 10)
  end
end
