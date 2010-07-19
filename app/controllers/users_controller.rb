class UsersController < ApplicationController
  include OauthLoginModule

  helper :missions
  @protected_actions = [ :edit, :update, :privacy, :destroy ]
  before_filter :login_required, :except => [ :show, :new, :create, :index, :profile_panel, :bottom_panel, :events_panel, :missions_panel, :checkuser, :signup, :status, :oauth_authorize, :oauth_success ]
  before_filter :load_user, :except => [ :index, :create, :new, :email_invite, :search, :checkuser, :signup, :status, :oauth_authorize, :oauth_success]
  before_filter :check_auth, :only => @protected_actions
  #before_filter :authenticate, :only => [ :become, :destroy, :promote, :demote, :set_password ]
  before_filter :get_most_recent_events, :only => [:new]
  permit 'site_admin', :only => [ :become, :destroy, :promote, :demote, :set_password ]
  permit 'site_admin or steward', :only => [ :delete_assets, :reset_login_delay ]
  before_filter :validate_brain_buster, :only => [:create]
  before_filter :create_brain_buster, :only => [:new]
  skip_before_filter :verify_authenticity_token, :only => [ :create, :oauth_authorize, :oauth_success ]
  protect_from_forgery :except => :checkuser

  delegate_url_helpers :for => UserAssetsController

  helper PrivacyHelper, MissionsHelper

  def checkuser
    exists = true

    unless params[:user_login].empty?
      begin
        @user = User.find_by_login(params[:user_login])
      rescue ActiveRecord::RecordNotFound
        exists = false
      end
    end

    render :text => exists, :layout => false
  end

  # List all users
  def index
    @page_title = 'Search and Browse the Players of '
    @events = Event.cached_list(10)

    respond_to do |format|
      format.html # index.rhtml
    end
  end

  # User profile page
  def show
    @page_title = @user.login + "'s Profile on "

    privacy_options = Preference.privacy_options_for @user
    @private_count = privacy_options[ :private_count ]
    @privacy_opts = privacy_options[ :privacy_opts ]

    # this is where we check if all the options are private and if so, redirect to the private page.
#    if @private_count == @privacy_opts.length and @user.id != current_user.id
#      respond_to do |format|

#        format.html { render :action => 'private' and return }
#        format.json { render :json => { :private => true }.to_json and return }
#      end
#    end

    # Fragment cache profile pages for logged out users only
#    if ! logged_in?
#      @cache_key = "profile_#{@user.login}"
#    else
#      @cache_key = nil
#    end

    # Only read the page from cache if you are not viewing your own page
#    unless @cache_key && read_fragment(@cache_key)
      @tools = Tool.cached_multi
      @classes = Hash["Bedouin" => 'bedouin',"Benefactor" => 'benefactor', "Destroyer" => 'destroyer', "Pathmaker" => 'pathmaker', "Seer" => 'seer', "Vigilante" => 'vigilante']

      # Get the profile owners last 10 events
      @events = @user.events.cached_your_news_feed(10)
      #      @contacts_events = @user.events.cached_news_feed_for(10)
      #      @allies_events = @user.events.cached_news_feed_for('ally', 10)
      #      @rivals_events = @user.events.cached_news_feed_for('rival', 10)

      # Get the list of missions per the request. Default to generated missions
      #      @missions = @user.get_mission_data({:mission_type => 'generated'}).paginate(:page => params[:missions_page], :per_page => 10) rescue []
      #      @generated_missions = @user.get_mission_data({:mission_type => 'generated'}).paginate(:page => params[:missions_page], :per_page => 10) rescue []
      #      @taken_missions = @user.get_mission_data({:mission_type => 'taken'}).paginate(:page => params[:missions_page], :per_page => 10) rescue []
      #      @favourite_missions = @user.get_mission_data({:mission_type => 'favorites'}).paginate(:page => params[:missions_page], :per_page => 10) rescue []
      #      @recommended_missions = @user.get_mission_data({:mission_type => 'recommended'}).paginate(:page => params[:missions_page], :per_page => 10) rescue []
      #      @queued_missions = @user.get_mission_data({:mission_type => 'queued'}).paginate(:page => params[:missions_page], :per_page => 10) rescue []

      # Get the list of forums per the request. Defaulted to generated topics.
      #      @topics = get_topic_data('generated').paginate(:page => params[:page], :per_page => 5)
      #      @subscribed_topics = get_topic_data('subscribed').paginate(:page => params[:page], :per_page => 5)
      #      @latest_posts = Post.latest(false, 5)

      # Get the top and recent awsm attacks
      #      @top_awsm_this_week = Awsmattack.top('awsm', 'this_week')
      #      @top_attack_this_week = Awsmattack.top('attack', 'this_week')
      #      @most_recent_awsm = Awsmattack.recent('awsm')
      #      @most_recent_attack = Awsmattack.recent('attack')

      @allies_count = @user.buddies.cached_contacts_count('ally')
      @rivals_count = @user.buddies.cached_contacts_count('rival')

      # these aren't used anywhere right now and put one hell of a beating on the server
      # for nothing. 05/06/2009 marc@gamelayers.com
      #@order_points = @user.order_points
      #@chaos_points = @user.chaos_points

      #@random_badge = Badge.random_unearned(@user)

      # set this flag to false when the player goes to their profile
      if @user.recent_signup
        @user.recent_signup = false
        @user.save
      end

      respond_to do |format|
        format.html # index.html.erb
        format.json {
          usrInfo = @user.to_json_overlay(:include_inventory => true)
          usrInfo[:recent_badges] = "private" unless show_content?(@user, current_user, "Badges")
          usrInfo[:recent_events] = "private" unless show_content?(@user, current_user, "Events")
          if not show_content?(@user, current_user, "Profile Information")
            usrInfo[:forename] = "private"
            usrInfo[:surname] = "private"
            usrInfo[:gender] = "private"
            usrInfo[:age] = "private"
            usrInfo[:country] = "private"
          end
          render :json => usrInfo.to_json, :layout => false
        }
        format.js do
          render :update do |page|
            page.replace_html 'user_missions', :partial => 'user_missions'
            unless params[:acquaintance_type].nil?
              page.replace_html 'user_acquaintances', :partial => 'acquaintances'
            end
            unless params[:forum_type].nil?
              page.replace_html 'user_forums', :partial => 'forums'
            end
            unless params[:tool].nil?
              page.replace_html "tool_use", "disabled" # Level.tool_requirements(@user, params[:tool])
              page.visual_effect :highlight, "tool_use", :duration => 2.0
            end
          end
        end
        format.rss { render :template => 'events/rss.xml.builder', :layout => false }
      end
    #end
  rescue Exception => e
    log_exception(e)
  end

  def profile_panel
   (['inventory', 'classes', 'tags', 'feeds', 'admin', 'steward', 'invitees', 'soul_marks'].include? params[:panel]) ? @panel = params[:panel] : @panel = 'general'
  end

  def bottom_panel
   (['missions', 'forums', 'awsmattack'].include? params[:panel]) ? @panel = params[:panel] : @panel = 'events'

    case @panel
      when 'events'
      @events = @user.events.cached_your_news_feed(10) rescue []
      when 'missions'
        if show_content?(@user, current_user, Preference.preferences[:mission_hist][:text])
          @missions = @user.get_mission_data({:mission_type => 'generated'}).paginate(:page => params[:missions_page], :per_page => 10) rescue []
        end
      when 'forums'
        if show_content?(@user, current_user, Preference.preferences[:forum_data][:text])
          # Get the list of forums per the request. Defaulted to generated topics.
          @topics = get_topic_data('generated').paginate(:page => params[:page], :per_page => 5).sort_by(&:created_at).reverse rescue []
          @subscribed_topics = get_topic_data('subscribed').paginate(:page => params[:page], :per_page => 5) rescue []
          @latest_posts = Post.latest(false, 5) rescue []
        end
      when 'awsmattack'
      # Get the top and recent awsm attacks
      @top_awsm_this_week = Awsmattack.top('awsm', 'this_week')
      @top_attack_this_week = Awsmattack.top('attack', 'this_week')
      @most_recent_awsm = Awsmattack.recent('awsm')
      @most_recent_attack = Awsmattack.recent('attack')
    end
  end

  def events_panel
   (['contacts', 'allies', 'rivals'].include? params[:panel]) ? @panel = params[:panel] : @panel = 'players'
    case @panel
      when 'players' then @events = @user.events.cached_your_news_feed(10)
      when 'allies' then @events = @user.events.cached_news_feed_for('ally', 10)
      when 'contacts' then @events = @user.events.cached_news_feed_for(10)
      when 'rivals' then @events = @user.events.cached_news_feed_for('rival', 10)
    end

    respond_to do |format|
      format.html
      format.js
      format.rss { render :template => 'events/rss.xml.builder', :layout => false }
    end
  end

  def missions_panel
   (['drafts', 'taken', 'queued', 'favorites', 'recommended'].include? params[:panel]) ? @panel = params[:panel] : @panel = 'generated'
    @missions = @user.get_mission_data({:mission_type => @panel}).paginate(:page => params[:missions_page], :per_page => 10) rescue []
  end

  # Search PMOG users
  def search
    redirect_to :index if params[:q].nil?

    query = params[:q] + '%'
    @users = User.find( :all, :conditions => [ 'email LIKE ? OR login LIKE ? OR forename LIKE ? OR surname LIKE ? OR url LIKE ?', query, query, query, query, query ], :limit => 10 )
    @page_title = 'Searching the Players of '

    respond_to do |format|
      format.html # index.rhtml
      format.json do
        render :json => { :results => @users.collect{ |u| u.to_json_overlay } }
      end
    end
  end

  # Form to register for PMOG
  def new
    if logged_in?
      flash[:notice] = "You are already logged in!"
      respond_to do |format|
        format.html {
          redirect_to '/'
        }
        format.json {
          render :json => flash.to_json, :status => 406
          flash.discard
        }
      end
    else
      @user = User.new
      @page_title = 'Create a player on '
      respond_to do |format|
        format.html {
          render :template => 'home/welcome'
        }
        format.json {
          render :json => {:captcha => @captcha, :secret_questions => SecretQuestion.find(:all)}.to_json(:except => :answer)
        }
      end
    end
  end

  # Form for editing a user
  def edit
    @page_title = 'Edit your Profile on '
    @user = User.find_by_login(params[:id])
    @preferences = Hash.new
    @classes = Hash["Bedouin" => 'bedouin',"Benefactor" => 'benefactor', "Destroyer" => 'destroyer', "Pathmaker" => 'pathmaker', "Seer" => 'seer', "Vigilante" => 'vigilante']
    prefs = {}
    Preference.preferences.each_pair{ | k, v | prefs[Preference.preferences[k][:text]] = Preference.preferences[k][:default] }
    # Assign any missing values to these preferenves.
    current_user.preferences.ensure_defaults_for(prefs).map{ |x| @preferences[x.name] = x.value }
    @preferences = OpenStruct.new(@preferences)

    @user_secret = @user.user_secret.nil? ? @user.build_user_secret : @user.user_secret

  end


  # Register for PMOG! Note that a lot of code is triggered in the user observer as a result of this.
  def create
    # Since we're not making the user confirm their password anymore
    # this will make the validation work.
    if not params["user"]["password"].empty?
      params["user"]["password_confirmation"] = params["user"]["password"]
    end

    begin
        @user = User.new(params["user"])
        @user.save!
        @user.reload

        # Build the UserSecret object if the params have the data.
        if params["user_secret"]
          secret = @user.build_user_secret(params["user_secret"])
          secret.save!
        end


          if !cookies[:share].nil?
            @share = MissionShare.find(cookies[:share])
            @share.convert!
          end

          Crate.create_on_profile(Location.find_or_create_by_url( 'http://' + request.env[ 'HTTP_HOST' ] + '/users/' + @user.login ))

          # Connect the BetaKey to the user, so that we can see who invited this user
          # the invite event (if it occurs) is hidden inside this call as well
          if cookies[:beta_key]
            User.set_betakey_for(@user, cookies[:beta_key])
          else
            Event.record :context => 'signup',
              :user_id => @user.id,
              :message => 'signed up!'
          end

          self.current_user = User.authenticate(@user.login, params[:user][:password])

          # Allow the user to login, too
          cookies[:auth_token] = { :value => @user.remember_token, :expires => @user.remember_token_expires_at }

          # NOTE disabled
          ## Set this variable in the session so we can track who is a new user and control their layout experience.
          #session[:new_user] = true

        respond_to do |format|
            format.html {
              flash[:notice] = 'You have successfully signed up for The Nethernet!'
              if params[:toolbar_installed]
                redirect_to(@share.nil? ? "/toolbarlanding" : mission_path(@share.mission))
              else
                redirect_to(@share.nil? ? "/home/install/" : mission_path(@share.mission))
              end
            }
            format.js
            format.json {
              render :json => create_new_session_overlay
            }
        end

    rescue ActiveRecord::RecordInvalid
      flash[:notice] = "There is an invalid record preventing the user account from being created"
      respond_to do |format|
        format.html {
          render :action => "new"
        }
        # format.js {
        #   render :action => "create_fail"
        # }
        format.json {
          render :json => render_full_json_response(:flash => flash, :errors => @user.errors), :status => 406
        }
      end
    rescue Exception => e
      log_exception(e)
      flash[:notice] = "There was a problem signing up, please try again. " + e
      respond_to do |format|
        format.html {
          render :action => "new"
        }
        # format.js {
        #   render :action => "create_fail"
        # }
        format.json {
          render :json => render_full_json_response(:flash => flash, :errors => @user.errors), :status => 406
        }
      end
    end
  end

  # Update a users' details
  def update
    @user = current_user

    @user.attributes = params[:user]

    respond_to do |format|
      if @user.save
        User.expire_cache(@user.login)
        Event.record :context => 'profile_updated',
          :user_id => @user.id,
          :message => 'just updated their profile.'

        flash[:notice] = 'You have successfully updated your profile.'
        format.html { redirect_to edit_user_path(@user) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end

  # List this users' badges
  def badges
    @page_title = @user.login + "'s Badges from "
  end

  # API only method, for setting and updating user preferences from the extension.
  def preferences
    @user.preferences.sound = params[:user][:sound]
    @user.save(false)

    respond_to do |format|
      format.js {
        # TODO - add the sound preference to the current_user_data hash
        overlay = {}
        overlay[:user] = current_user_data
        add_empty_page_objects_to(overlay)
        render :json => OpenStruct.new(overlay).to_json
      }
    end
  end

  def email_invite
    if params[:recipient].empty?
      flash[:notice] = 'No email supplied :('
      render :partial => 'shared/invites'
    elsif BetaUser.email_invite(current_user, params)
      flash[:notice] = 'Invite sent!'
      render :partial => 'shared/invites'
    else
      flash[:notice] = 'Email already in use, please try another!'
      render :partial => 'shared/invites'
    end
  end

  # Tag this user
  def add_tag
    begin
      raise Exception.new("Invalid tag") if params[:tag][:name].empty?
      @user = User.find_by_login(params[:id])
      new_tags = params[:tag][:name].split(",")
      @user.tag_list.add(new_tags)
      @user.save(false)
      @new_tag = @user.reload.tags.last
      current_user.reward_datapoints(1)
    rescue Exception => e
      render :update do |page|
        page.replace_html "tag_error", "Invalid Tag Entered"
        page.visual_effect :appear, "tag_error"
        page.visual_effect :shake, "tag_name"
        page.visual_effect :fade, "tag_error", :duration => 5.0
      end
    end
  end

  # Un-tag this user
  def remove_tag
    @user = User.find_by_login(params[:id])
    @tag_to_delete = @user.tags.find(params[:tag_id])
    current_user.reward_datapoints(1)
    if @tag_to_delete
      @user.tags.delete(@tag_to_delete)
    else
      render :nothing => true
    end

    respond_to do |format|
      format.js {
        render :action => 'add_tag.rjs'
      }
    end
  end

  # Trustee/Steward only method for clearing a players avatar
  def delete_assets
    return head(:method_not_allowed) unless request.delete?
    @user = User.find_by_login(params[:id])
    @user.assets = []
    if @user.save(false)
      Stewarding.create(:user => current_user, :action => 'delete_assets', :stewardable => @user)
      flash[:notice] = "Assets deleted"
    end
    redirect_to "/users/#{@user.login}"
  end

  # Trustee/Steward only method for resetting the login delay if a user has problems logging in
  def reset_login_delay
    return head(:method_not_allowed) unless request.delete?
    @user = User.find_by_login(params[:id])
    @user.last_login_attempt = nil
    @user.failed_login_attempts = 0
    if @user.save(false)
      Stewarding.create(:user => current_user, :action => 'reset_login_delay', :stewardable => @user)
      flash[:notice] = "Login delay removed"
    end
    redirect_to "/users/#{@user.login}"
  end

  # Log in as a given user, admin only
  def become
    if current_user.has_role?('site_admin')
      self.current_user = User.find( :first, :conditions => { :login => params[:id] } )
      self.current_user.remember_me
      cookies[:auth_token] = { :value => self.current_user.remember_token , :expires => self.current_user.remember_token_expires_at }
      flash[:notice] = 'Logged in as ' + self.current_user.login
    else
      flash[:notice] = 'Failed to login as ' + self.current_user.login
    end
    redirect_to('/')
  end

  # Turn user into steward, admin only
  def promote
    if current_user.has_role?('site_admin')
      @user.has_role 'steward'
      record_event :user => @user, :context => 'steward_created', :message => "got a promotion to Steward from <a href=\"#{user_path(current_user)}\">#{current_user.login}</a>."
      flash[:notice] = @user.login + ' is now a Steward.'
    else
      flash[:error] = 'Trouble promoting ' + @user.login + '.'
    end
    redirect_to user_path(@user)
  end

  # Turn steward into normal user, admin only
  def demote
    if current_user.has_role?('site_admin')
      @user.has_no_role 'steward'
      flash[:notice] = @user.login + ' is now a regular user.'
    else
      flash[:error] = 'Trouble demoting ' + @user.login + '.'
    end
    redirect_to user_path(@user)
  end

  # Allow a user to login again, following repeated login failures
  def unlock
    if current_user.has_role?('site_admin')
      @user.unlock_account
      flash[:notice] = "Account unlocked"
    else
      flash[:notice] = "Error unlocking account"
    end
    redirect_to user_path(@user)
  end

  # Mark a user as properly welcome to PMOG
  def welcome
    if current_user.admin_or_steward?
      @user.welcomed = true
      @user.save(false)
      flash[:notice] = @user.login + " is now marked as Welcomed to PMOG"
    else
      flash[:notice] = "An error occurred"
    end
    respond_to do |format|
      format.js
      format.html do
        redirect_to :back
      end
    end
  end

  # Rate a user and update their average rating
  def rate
    @user = User.find(params[:id])
    if params[:rating]
      unless @user.ratings.find_by_user_id(current_user.id)
        @user.ratings.create( :user_id => current_user.id, :score => params[:rating] )
        @user.calculate_average_rating
        @user.calculate_total_ratings
        User.expire_cache(@user.login)
      end
    end
  end

  # Set a new password for this user
  def set_password
    @user = User.find_by_login(params[:id])

    @user.password = params[:user][:password]
    @user.password_confirmation = params[:user][:password_confirmation]

    respond_to do |format|
      if @user.save
        flash[:notice] = 'Password was successfully updated'
        format.html { redirect_to(edit_user_path(@user)) }
      else
        format.html { render :action => "show" }
      end
    end
  end

  # Allow the user to set their primary class
  def set_primary_class
    class_name = (params[:class] == 'skip' ? CLASSES.values.rand.downcase : params[:class])

    begin
      current_user.user_level.assign_primary(class_name)
      flash[:notice] = "Primary class set to #{class_name.titleize}"
    rescue UserLevel::InvalidClassnameError
      flash[:error] = "Invalid classname specified.  You tried: #{class_name}"
    end

    redirect_to user_path(current_user)
  end

  # Deprecated? Can we remove this?
  def user_missions
    @user = User.find_by_login(params[:id])
    @headers["Content-Type"] = "application/xml"
    @missions = @user.missions
    render :layout => false
  end

  def render_or_redirect_for_captcha_failure
    @user = User.new(params[:user])
    @user.valid?
    @user.errors.add("captcha_answer", "invalid or incorrect")
    respond_to do |format|
      format.html {
        render :action => 'new'
      }
      format.js {
        render :action => "create_fail"
      }
      format.json {
        render :json => render_full_json_response(:errors => @user.errors), :status => 406
      }
    end
  end

  def status
    respond_to do |format|
      format.json do
        if session[:user].nil?
          flash[:error] = "Not logged in!"
          response.headers["Content-Type"] = "text/json; charset=utf-8"
          render :json => flash.to_json, :status => 406
          flash.discard
        else
          flash[:notice] = "Already logged in!"
          response.headers["Content-Type"] = "text/json; charset=utf-8"
          render :json => render_full_json_response(:flash => flash), :status => 201
          flash.discard
        end
      end
    end
  end

  protected

  # Loads the required user. If +current_user+ and the requested user are the same, skips caching
  def load_user
    if logged_in? and current_user.login == params[:id]
      @user = current_user
    else
      @user = User.caches(:find_by_login, :with => params[:id], :ttl => 1.day)
    end

    @suspended = @user.suspended?

    # This should always be set, but just to be sure...
    @user.active_class if @user.primary_association.nil?
  rescue ActiveRecord::RecordNotFound => e
    flash[:error] = "Player Not Found"

    respond_to do |format|
      format.html { redirect_to home_url and return false }
      format.json { render :json => render_full_json_response(:flash => flash), :status => 404 }
    end
  end

  def check_auth
    current_user == @user or site_admin? or raise AccessDenied
  end

  private
  def get_topic_data(type = 'generated')
    case type
      when 'generated'
      Topic.cached_generated(@user, current_user.is_a?(User) && current_user.admin_or_steward?)
      when 'subscribed'
      if logged_in? && current_user.admin_or_steward?
        topic_ids = @user.subscribed_ids
      else
        topic_ids = @user.public_subscribed_ids
      end
      topics = []
      topic_ids.each do |id|
        # Don't use find(id) as that raises errors if the topic has been deleted
        # Use find(:first, :conditions => etc) so that we get nil back
        t = Topic.caches(:find, :withs => [:first, {:conditions => {:id => id}}])
        topics << t unless t.nil?
      end
      topics.flatten
    end
  end

  def get_most_recent_events
    @events = Event.find(:all, :joins => "LEFT JOIN users ON events.user_id=users.id", :select => "events.*, users.login AS user_login", :order => 'created_at DESC', :limit => 10)
  end

end
