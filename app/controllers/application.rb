# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base

  rescue_from ActionController::RoutingError, :with => :render_404
  rescue_from ActionController::MethodNotAllowed, :with => :invalid_method

  include PingbackHelper
  helper :pingback

  # CSRF protection. This is easy enough to use in Rails 2.0 since
  # all the form helpers include the hidden tag. However, any hand
  # made forms will need to include <%= token_tag %>. Note that
  # the extension receives the authenticity_token along with
  # the user data in +current_user_data+ and has been wired up
  # to send it back to us on every relevant request
  protect_from_forgery :secret => 'er1c_c4nt0na'

  include AuthenticatedSystem
  include OverlaySystem
  include ExceptionLoggable

  # Pick a unique cookie name to distinguish our session data from others'
  session :session_key => 'thenethernet_session_id'

  # Disable sessions for robots and spiders
  session :off, :if => proc { |request| is_megatron?(request.user_agent) }

  layout 'main'

  before_filter :redirect_from_pmog
  before_filter :firewall
  # before_filter :login_from_cookie
  # before_filter :login_from_browser
  before_filter :last_seen
  before_filter :set_host
  before_filter :local_cache_for_request
  before_filter :sanitize_params
  before_filter :check_for_suspended

  around_filter :set_timezone
  around_filter :catch_errors

  after_filter OutputCompressionFilter

  filter_parameter_logging :password, :password_confirmation

  class AccessDenied < StandardError; end

  def render_403
    respond_to do |format|
      format.html { render :file => "#{RAILS_ROOT}/public/404.html", :status => '403 Forbidden' }
      format.xml  { render :nothing => true, :status => '403 Forbidden' }
      format.js   { render :nothing => true, :status => '403' }
      format.json { render :nothing => true, :status => '403' }
    end
    true
  end

  def render_404
    respond_to do |format|
      render :text => 'A server error occurred, and has been logged for inspection by the development team.' and return if request.xhr?
      format.html { render :file => "#{RAILS_ROOT}/public/404.html", :status => '404 Not Found' }
      format.xml  { render :nothing => true, :status => '404 Not Found' }
      format.js   { render :json => create_error_overlay('A server error occurred, and has been logged for inspection by the development team.'), :status => '404' }
      format.json { render :json => create_error_overlay('A server error occurred, and has been logged for inspection by the development team.'), :status => '404'  }
    end
    true
  end

  def render_500(message = nil)
    respond_to do |format|
      render :text => 'A server error occurred, and has been logged for inspection by the development team.' and return if request.xhr?
      format.html { render :file => "#{RAILS_ROOT}/public/500.html", :status => '500' }
      format.xml  { render :nothing => true, :status => '500' }
      format.js   { render :json => create_error_overlay('A server error occurred, and has been logged for inspection by the development team.'), :status => '500' }
      format.json { render :json => create_error_overlay('A server error occurred, and has been logged for inspection by the development team.'), :status => '500' }
    end
    true
  end

  # Handling some backwards compatabilty breakage, note that we render
  # a generic 500 to html requests, and a 422 (upgrade required) to the extension
  def render_upgrade_notice
    respond_to do |format|
      format.html { render :file => "#{RAILS_ROOT}/public/500.html", :status => '500' }
      format.json {
        flash[:notice]= "An upgrade for PMOG is available! Please <a style=\"cursor:pointer;text-decoration:underline;\" href=\"#{host}/help/toolbar\">install it</a> to continue playing. Or visit <a href='http://pmog.com'>PMOG.com</a> to learn more."
        render :json => create_overlay('messages', { :type => 'message', :text => message_overlay({ :content => flash[:notice], :from => 'pmog' }) })
        flash.discard
      }
    end
    true
  end

  # def rescue_action_in_public(e)
  #   log_exception(e)
  #   case e when ActiveRecord::RecordNotFound
  #     render_404(e.message)
  #   when ActionController::RoutingError
  #     e.message =~ /No route matches "\/system\/image_assets\/*/ ? reset_user_avatar(e.message) : render_404(e.message)
  #   when ActionController::InvalidAuthenticityToken
  #     render_upgrade_notice
  #   else
  #     render_500(e.message)
  #   end
  # end

  # So that we can test exception handling locally
  # def rescue_action_locally(e)
  #   log_exception(e)
  #   case e when ActionController::InvalidAuthenticityToken
  #     render_upgrade_notice
  #   when ActionController::RoutingError
  #     e.message =~ /No route matches "\/system\/image_assets\/*/ ? reset_user_avatar(e.message) : render_404(e.message)
  #   else
  #     super
  #   end
  # end

  # Only used by the forums, for now
  def last_seen
    @last_seen = cookies[:last_seen]
    cookies[:last_seen] = { :value => Time.now.to_s(:db), :expires => 2.weeks.from_now }
  end

  # So that we can construct properly formed urls in emails
  def set_host
    ActionMailer::Base.default_url_options[:host] = request.host_with_port
    @remote_ip = request.env['REMOTE_ADDR'] # remember the remote host
  end

  # PMOG is now TheNethernet
  def redirect_from_pmog
    if request.env['HTTP_HOST'] == 'dev.pmog.com'
      redirect_to 'http://dev.thenethernet.com' + request.env['REQUEST_PATH'].to_s, :status => 301
    elsif request.env['HTTP_HOST'] == 'ext.pmog.com'
      redirect_to 'http://ext.thenethernet.com' + request.env['REQUEST_PATH'].to_s, :status => 301
    elsif request.env['HTTP_HOST'] == 'pmog.com' || request.env['HTTP_HOST'] == 'bud.com'
      redirect_to 'http://thenethernet.com' + request.env['REQUEST_PATH'].to_s, :status => 301
    end
  end

  # Stopping the 5cr1pt k1dd3s, one fucker at a time
  # IPs taken from pmog.com/suspects
  def firewall
    banned_ips = []
    render :nothing => true and return if (RAILS_ENV == 'production' and banned_ips.include? request.env[ 'REMOTE_ADDR' ])
  end

  # Attack! Helper to record the +user+, +creator+ and +location+ of this attack
  def record_attack(options={})
    Awsmattack.create_and_deposit(options[:user], options[:minelayer], options[:location], 'mine')
  end

  # Awsm! Helper to record the +user+, +creator+ and +location+ of this awsm
  def record_awsm(options={})
    Awsmattack.create_and_deposit(options[:user], options[:cardlayer], options[:location], 'dp_card')
  end

  # In-game event messaging hook, for user signups, levelling up, etc
  def record_event(options={})
    Event.record(options)
  end

  # Send an IM from the PMOG user
  def send_pmog_message(options={})
    Message.send_pmog_message(options)
  end

  # Shortcut to the latest events across the site
  def latest_events
    Event.cached_list
  end

  # User admin status
  def site_admin?
    #@site_admin ||= (logged_in? and current_user.caches(:has_role?, :with => 'site_admin', :ttl => 1.week))
    @site_admin ||= (logged_in? and current_user.has_role?('site_admin'))
  end

  # User 'steward' status
  def steward?
    #@steward ||= (logged_in? and current_user.caches(:has_role?, :with => 'steward', :ttl => 1.week))
    @steward ||= (logged_in? and current_user.has_role?('steward'))
  end

  def load_play_weights
    # Cached via the User model, which is a bit of hack, sorry - duncan 05/11/08
    User.get_cache('weights', :ttl => 1.day) do
      YAML.load_file(WEIGHTS_FILE)
    end
  end

  # From RESTful Web Services:
  #
  # A wrapper for actions whose views support conditional HTTP GET.
  # If the given value for Last-Modified is after the incoming value
  # of If-Modified-Since, does nothing. If Last-Modified is before
  # If-Modified-Since, this method takes over the request and renders
  # a response code of 304 ("Not Modified").
  #
  # Usage example, where last_modified is a database timestamp:
  #
  # render_not_modified_or(last_modified) do
  #   respond_to do |format|
  #     format.html
  #     format.js { render :json => @blah }
  #   end
  # end
  def render_not_modified_or(last_modified)
    if last_modified
      response.headers['Last-Modified'] = last_modified.httpdate rescue nil
    end

    if_modified_since = request.env['HTTP_IF_MODIFIED_SINCE']
    if_modified_since = nil if if_modified_since.nil? || if_modified_since.empty?
    if if_modified_since && last_modified && last_modified <= Time.httpdate(if_modified_since)
      # The representation has not changed since it was last requested.
      # Instead of processing the request normally, send a response
      # code of 304 ("Not Modified").

      # Note that just sending the 304 status code isn't enough. An AJAX call will see that
      # but still return a 200 status code as it considers the request successful. We'll set
      # a custom header here so that the extension can check for a 200 and PMOG_304 header,
      # and then perform a conditional GET. See http://torrez.us/archives/2006/07/02/469/
      response.headers['PMOG_304'] = true

      render :nothing => true, :status => 304
    else
      # The representation has changed since it was last requested.
      # Proceed with normal request processing.
      yield
    end
  end

  def new_version_available
    # Note that this won't tell you if a patch version is available, since
    # 0.5.01.to_f is equal to 0.5.02.to_f - duncan 30/09/08
    (params[:version] && PMOG_EXTENSION_VERSION.to_f > params[:version].to_f) ?  true : false
  end

  # Quick and dirty xss prevention
  def simple_sanitize(text)
    text.gsub(/[^[:alnum:] '"-\.]+/, '_')
  end

  # Check to see if the user agent is a bot of any description - useful for disabling sessions for them
  # See http://gurge.com/blog/2007/01/08/turn-off-rails-sessions-for-robots/
  def self.is_megatron?(user_agent)
    user_agent =~ /b(Baidu|Gigabot|Googlebot|libwww-perl|lwp-trivial|msnbot|SiteUptime|Slurp|WordPress|ZIBB|ZyBorg)b/i
  end

  # Simple UUID helper, mainly for non-sequential primary ids
  def create_uuid
    UUID.timestamp_create().to_s
  end

  # The full host including the port. Note that we don't
  # want to reveal the use of ext.pmog.com in the overlays
  # so we have a rewrite for that.
  def host
    if request.env[ 'HTTP_HOST' ] =~ /ext.pmog.com/ || request.env[ 'HTTP_HOST' ] =~ /ext.thenethernet.com/
      return 'http://thenethernet.com'
    else
      return 'http://' + request.env[ 'HTTP_HOST' ] rescue 'http://localhost:3000'
    end
  end

  # Returns +true+ if the user has turned off sounds
  def sound_off?(options = {})
    current_user.get_cache("sound_off?_#{options}") do
      options = { :user => current_user }.merge(options)

      # Allow Sound Effects is easy
      sound_effects_setting = options[:user].preferences.setting("Allow Sound Effects").to_bool

      # Sound setting is a bit more problematic, so we need to force it into a boolean shape
      sound_setting = options[:user].preferences.setting(:sound).to_s
      sound_setting = false if sound_setting.nil? or sound_setting.empty?
      sound_setting = false if sound_setting == 'off'
      sound_setting = true if sound_setting == 'on'
      sound_setting = sound_setting.to_bool

      (sound_effects_setting or sound_setting) ? false : true
    end
  end
  helper_method :sound_off?

  protected

  def self.protected_actions
    [ :edit, :update, :destroy ]
  end

  # Require basic auth for actions unless you're running on staging or locally
  def authenticate
    unless [ 'development', 'staging', 'test' ].include? Rails.env
      authenticate_or_request_with_http_basic do |username, password|
        username == "pmog" && password == "itsasekrit"
      end
    end
  end

  def route_not_found
    render :text => "Whatever you're looking for isn't there", :status => :not_found
  end

  def invalid_method
    message = "I don't know how to '#{request.request_method.to_s.upcase}'"
    render :text => message, :status => :method_not_allowed
  end

  private
  # This checks to see if the user is suspended and if so, never let's them see anything.
  # Return a 403 forbidden status to the extension so it doesn't puke
  def check_for_suspended
    begin
      if logged_in? && current_user.caches(:suspended?, :ttl => 1.day)
        flash[:error] = "Your account has been suspended until #{current_user.suspended_until}"
        respond_to do |format|
          format.html { render :template => "/shared/suspended" }
          format.js   { render :nothing => true, :status => 403 }
          format.json { render :nothing => true, :status => 403 }
        end
      end
    rescue NoMethodError => e
      # For some reason there are errors with current_user.suspended? like this:
      # "undefined method `suspended?' for #", so let's catch them here
      #puts "== current_user.suspended? error start =="
      #puts current_user.inspect
      #puts "== current_user.suspended? error end =="
    end
  end

  def set_timezone
    TzTime.zone = logged_in? ? current_user.tz : TimeZone.new('Etc/UTC')
      yield
    TzTime.reset!
  end

  def catch_errors
    begin
      yield
    rescue AccessDenied
      flash[:notice] = 'You do not have access to that area.'
      redirect_to '/'
    rescue ActiveRecord::RecordNotFound
      respond_to do |format|
        format.html { render :file => "#{RAILS_ROOT}/public/404.html", :status => '404 Not Found' }
        format.xml  { render :nothing => true, :status => '404 Not Found' }
        format.js   { render :json => '404'.to_json, :status => '404 Not found' }
        format.json   { render :json => '404'.to_json, :status => '404 Not found' }
      end
    end
  end

  # Whilst the CSRF stuff catches 90% of the problems we might run into, it's also prudent
  # to ensure that the referrer is a trusted one, especially when deploying tools, for example.
  # This method checks the referrer and the environment, to make sure they match up. This prevents
  # people from scripting an attack that will extract the authenticity_token from the user, and then
  # reusing it for nefarious purposes, since it doesn't not change for the lifetime of a session.
  # Note that when the referrer and the environment don't line up, the user is redirected.
  def check_referrer
    begin
      if RAILS_ENV == 'production'
        trusted = (request.env[ 'HTTP_REFERER' ].starts_with?('http://pmog.com') || request.env[ 'HTTP_REFERER' ].starts_with?('http://thenethernet.com') )
      elsif RAILS_ENV == 'staging'
        trusted = (request.env[ 'HTTP_REFERER' ].starts_with?('http://dev.pmog.com') || request.env[ 'HTTP_REFERER' ].starts_with?('http://dev.thenethernet.com') )
      elsif RAILS_ENV == 'development'
        trusted = (request.env[ 'HTTP_REFERER' ].starts_with?('http://0.0.0.0:3000') || request.env[ 'HTTP_REFERER' ].starts_with?('http://localhost:3000') )
      elsif RAILS_ENV == 'test'
        trusted = (request.env[ 'HTTP_REFERER' ].starts_with?('http://example.com') || request.env[ 'HTTP_REFERER' ].starts_with?('http://test.host') )
      end
    rescue NoMethodError => e
      if RAILS_ENV == 'test'
        trusted = true
      else
        trusted = false
      end
    end

    if trusted
      return true
    else
      flash[:notice] = 'Something went wrong'
      redirect_to '/' and return
    end
  end

  # If user avatar pictures are messed up, let's reset them
  # and send a PMail to let them know what happened.
  # - note that we only send one PMail per month, to reduce spam
  def reset_user_avatar(exception)
    filename = exception.split('/')[7].split(' ')[0].split('"')
    asset = Asset.find(:first, :conditions => {:filename => filename})
    user = (asset.parent.nil? ? asset.attachable : asset.parent.attachable)

    # If we have the asset, just attempt to regenerate it and reset the database,
    # otherwise, wipe their assets so that the default appears, and PMail them
    if File.exists?(asset.full_filename)
      user.assets[0].update_attributes(nil)
    else
      user.assets = []
      user.save(false)
      title = 'Avatar reset ' + Date.today.strftime("%b %y")
      body = "Your avatar appears to have gone missing, sorry. We've reset you to the default so please try uploading a new picture!"
      send_pmog_message( :recipient => user, :title => title, :body => body ) unless user.messages.find_by_title(title)
    end
  end
end
