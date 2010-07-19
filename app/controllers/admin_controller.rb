class AdminController < ApplicationController
  before_filter :login_required
  ##before_filter :authenticate
  permit 'site_admin or steward'
  caches_action :index, :stats, :badges

  def index
    @tools = Tool.cached_multi
    @page_title = 'Admin on '
    @total_users = User.caches(:count)
    @total_beta_users = BetaUser.caches(:count)
    @invited_beta_users = BetaUser.caches(:count_invited)
    @uninvited_beta_users = BetaUser.caches(:count_uninvited)
    @signed_up_beta_users = BetaUser.caches(:count_signed_up)
    @chaos_point_totals = 'Disabled' #ToolUse.chaos_counts
    @order_point_totals = 'Disabled' #ToolUse.order_counts
  end

  def auto_acquaintances
    params[:id] ? @user = User.find_by_login(params[:id]) : @user = current_user
  end

  def stats
    @page_title = 'Stats for '
  end

  def api
    @page_title = 'Admin : API test for '
    @location = Location.find_or_create_by_url( 'http://www.suttree.com' )

    if @location.portals.empty?
      current_user.portals.create( :location_id => @location.id, :destination_id => @location.id )
    end

    if @location.crates.empty?
      current_user.crates.create( :location_id => @location.id )
    end

    @portal = Portal.find(:first)
    @crate = Crate.find(:first)
  end

  # Add a soulmark to a user
  def soul_mark
    @user = User.find(:first, :conditions => {:login => params[:id] } )
    @user.soul_marks.create(:admin_id => current_user.id, :comment => params[:comment])
  end

  def delete_soul_mark
    mark = SoulMark.find(params[:id])
    @user = mark.player
    mark.destroy
    render :action => :soul_mark
  end

  # Viewing a users' inventory
  def inventory
    @user = User.find( :first, :conditions => { :login => params[:id] } )
    @page_title = "Edit Game Status for " + @user.login + ", a player on "
  end

  # don't do this by accident
  def delete_inventory
    @user = User.find( :first, :conditions => { :login => params[:id] } )
    @user.inventory.zero_all
    flash[:error] = "Inventory Destroyed.  HAIL TO THE BURDENATOR!"
    redirect_to :action => 'inventory', :id => @user.login
  end

  # Edit a users tool count
  def update_inventory
    @user = User.find( :first, :conditions => { :login => params[:id] } )
    @user.inventory.set(params[:tool], params[:value].to_i)
    render :text => @user.inventory.send(params[:tool])
  end

  def update_classpoints
    @user = User.find( :first, :conditions => { :login => params[:id] } )
    @user.user_level.update_attributes({"#{params[:class_name]}_cp".to_sym => params[:value].to_i})
    render :text => @user.user_level.send("#{params[:class_name]}_cp")
  end

  # Edit a users datapoints
  def update_datapoints
    @user = User.find( :first, :conditions => { :login => params[:id] } )

    if params[:value].to_i > @user.datapoints
      difference = params[:value].to_i - @user.datapoints
      @user.reward_datapoints(difference, params[:lifetime])
    elsif params[:value].to_i < @user.datapoints
      difference = @user.datapoints - params[:value].to_i
      @user.deduct_datapoints(difference)
    end
    render :text => @user.datapoints
  end

  # Edits a users pings
  def update_pings
    @user = User.find( :first, :conditions => { :login => params[:id]} )

    if params[:value].to_i > @user.available_pings
      difference = params[:value].to_i - @user.available_pings
      @user.reward_pings(difference, params[:lifetime])
    elsif params[:value].to_i < @user.available_pings
      difference = @user.available_pings - params[:value].to_i
      @user.deduct_pings(difference)
    end
    render :text => @user.available_pings
  end

  # Admins can generate DP from thin air!
  def free_credits
    current_user.reward_datapoints(1000)
    render :partial => 'free_credits'
  end

  # Admin page to view the results of the +Sql Profiler+ plugin
  def sql_profiler
    @page_title = 'Admin : sql_profiler for '
    @sql_queries = SqlProfiler.top(100)
  end

  def nsfw_moderation
    @page_title = 'NSFW Moderation on '
    # This is pretty complex but it works with good performance!
    @missions = Mission.find_by_sql('SELECT * FROM missions JOIN votes WHERE missions.id = votes.voteable_id AND missions.nsfw = 1 GROUP BY votes.voteable_id HAVING COUNT(votes.voteable_id) >= 3')
  end

  def message_as_npc
    @replace_id = 'npc_message_response'

    begin
      npc = User.find_by_login(params[:message][:login])
    rescue ActiveRecord::RecordNotFound
      flash[:error] = "Couldn't find an NPC by the name " + params[:message][:login]
      return
    end

    title = 'New message from ' + npc.login
    body = params[:message][:body]

    # Replace all links with tinyurls
    URI.extract(body).each do |uri|
      tiny_uri = tiny_url(uri)
      body.gsub!(uri, tiny_uri)
    end

    if (params[:message][:class].empty?)
      begin
        @users = User.find(:all, :conditions => [ "last_login_at > ?", 1.week.ago ] )
      rescue ActiveRecord::RecordNotFound
        flash[:error] = "Couldn't find any players active within the last week. Are you playing locally?"
        return
      end
    else
      begin
        #uls = UserLevel.find(:all, :conditions => ['primary_class = ?', params[:message][:class]]).collect{|i| i.user_id}
        @users = User.find(:all, :include => "user_level", :conditions => [ 'user_levels.primary_class = ? AND last_login_at >= ?', params[:message][:class], 1.week.ago   ] )
      rescue ActiveRecord::RecordNotFound
        flash[:error] = "Couldn't find any " + params[:message][:class].pluralize + " active in the last week"
        return
      end
    end

    if (@users.nil? or @users.empty?)
      flash[:error] = "There are no active players that match the desired criteria"
    else
      @users.each do |recipient|
        Message.create( :title => title, :body => body, :user_id => npc.id, :recipient => recipient)
        recipient.messages.clear_cache
      end
      flash[:notice] = "Message sent to all players active in the last week."
    end
  end

  # Send a mesasge as the pmog user
  def message_as_pmog
    # Argh.. ripped from MessagesController::create.
    title = 'New message from ' + SYSTEM_USER.login
    body = params[:message][:body]
    @replace_id = 'message_response'

    # Replace all links with tinyurls
    URI.extract(body).each do |uri|
      tiny_uri = tiny_url(uri)
      body.gsub!(uri, tiny_uri)
    end

    recipients = Message.determine_recipients(body)
    recipients.each do |recipient|
      Message.create( :title => title, :body => body, :user_id => SYSTEM_USER.id, :recipient => recipient)
      recipient.messages.clear_cache
    end

    flash[:notice] = "Message sent!"

    render :action => 'message_as_npc.rjs'
  end

  # View the messages sent to the PMOG user
  def pmog_inbox
    @user = User.find_by_email('self@pmog.com')
    @page_title = current_user.login + '\'s Messages on '
    @messages = @user.messages.page(params[:page])
    @messages.collect{ |m| m.mark_as_read unless m.read? }
  end

  def test
    @page_title = "Test Data Dumps from "
  end

  # Test the cache effectiveness against the current_user_data call
  def test_current_user_data
    overlay = {}
    overlay[:user] = current_user_data
    render :text => overlay.inspect
  end

  def test_overlay_partial
    # Some dummy data for the various partials, add to this if required
    @mine = Mine.find :first
    @crate = Crate.find :first
    @location = Location.find :first

    # Edit the name of the partial file to debug other templates
    render :partial => 'users/show.js.erb', :locals => { :user => current_user, :crate => @crate, :mine => @mine, :location => @location }, :layout => false
  end

  def incomplete_mission_takings
    @page_title = 'Incomplete Missions on '
    @timeframe = 1.hour.ago.to_s(:db)
    @missions = Mission.find(:all, :include => 'takers', :conditions => ['takings.created_at > ?', @timeframe])
  end

  def top_missionaters
    @page_title = 'Top Mission Makers on '
    @users = User.find(:all, :select => 'COUNT(missions.id) as count_all, users.id, users.login, users.created_at', :joins => 'left outer join missions on missions.user_id=users.id AND missions.is_active = 1', :group => 'missions.user_id', :order => 'count_all desc', :limit => 100)
  end

  def user_tooluse
    @user = User.find_by_login(params[:user][:login])
    @tool_use = @user.tool_uses.filter(params[:user][:tool]).size
  end

  def user_upgradeuse
    @user = User.find_by_login(params[:user][:login])
    @upgrade_use = @user.upgrade_uses.filter(params[:user][:upgrade]).size
  end

  # A controller to allow an admin to change the user's password if the reset password notifications are not getting to
  # the user.
  def change_user_password
    @page_title = 'Admin : Change Player Password for'
    if request.post?
      begin
        @user = User.find_by_login(params[:login])
      rescue
        flash[:notice] = 'Player not found'
        redirect_to :action => 'change_user_password'
        return
      end
      @user.password = params[:password]
      @user.password_confirmation = params[:password_confirmation]
      if @user.save
        flash[:notice] = "Player's password updated successfully"
        redirect_to :controller => 'users', :action => 'index'
      else
        render :action => 'change_user_password'
      end
    end
  end


  def change_user_login
    @page_title = 'Admin : Change Player Login for'
    if request.post?
      begin
        @user = User.find_by_login(params[:login])
      rescue
        flash[:notice] = 'Player not found'
        redirect_to :action => 'change_user_login'
        return
      end
      @user.login = params[:new_login]
      if @user.save
        flash[:notice] = "Player's login updated successfully"
        redirect_to :controller => 'users', :action => 'show', :id => @user.login
      else
        render :action => 'change_user_login'
      end
    end
  end


  # A debug view to show data related to missions that is null and thus could be causing issues with the mission overlays
  # and missions in general
  def null_mission_data
    @page_title = "Null Mission Datas of "
    # List the branches that have a null location_id
    @null_branch_locations = Branch.find(:all, :conditions => ['location_id IS NULL'], :order => 'created_at DESC')

    # List the locations with a null url
    @null_location_urls = Location.find(:all, :conditions => ['url IS NULL'], :order => 'created_at DESC')
  end

  def badges
    @page_title = "Users per Badge on "
    @badges = Badge.find(:all, :select => "badges.*, count(badgings.user_id) AS user_count", :joins => "INNER JOIN badgings ON badgings.badge_id = badges.id", :group => "badges.id", :order => "name ASC")
  end

  # A view to display the pings, and allow editing of the ping valuations.
  def pings
    @page_title = "Pings Administration for "
    @ping_values = Ping.find(:all)

    if request.post?
      params[:value].each_pair do |k,v|
        i = Ping.find_by_name k
        i.update_attribute :points, v
        Ping.clear_cache(i.name)
      end
      redirect_to :action => 'pings'
    end
  end

  def order_chaos
    @page_title = "Order/Chaos Administration for "
    @order_chaos_values = OrderChaos.find(:all)

    if request.post?
      params[:value].each_pair do |k,v|
        i = OrderChaos.find_by_name k
        i.update_attributes :points, v
      end
      redirect_to :action => 'order_chaos'
    end
  end
end
