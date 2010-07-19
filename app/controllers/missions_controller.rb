class MissionsController < ApplicationController
  helper :queued_mission
  before_filter :login_required, :except => [ :index, :show, :highest_rated, :pmog_missions, :user_favorites, :association ]
  before_filter :sort_param, :only => [ :association, :highest_rated, :user_missions, :user_favorites, :pmog_missions ]
  before_filter :can_edit?, :only => [ :lightposts, :overview, :edit, :add_lightposts ]
  before_filter :check_inactive_mission, :only => [ :show ]
  after_filter :record_stats, :only => [ :dismiss, :queue, :take ]

  ############################################################################################
  # VIEWING MISSIONS
  ############################################################################################

  # The main index view (i.e; /missions path)
  def index
    if logged_in? and current_user.missions.completed.empty?
      redirect_to "/missions/pmog"
      return
    end

    # By default we'll show the latest missions on PMOG
    @page_title = 'Missions Created on '
    @img = nil # No image associated with the latest missions
    @heading_text = ['Latest', '/missions'] # "Missions" is already included in the partial so this will be shown as "Latest Missions"

    # Always show the last 10 missions for the rss feed
    #@rss_missions = Mission.find(:all, :limit => 10, :order => "missions.created_at DESC")

    #@missions = @rss_missions.paginate(:page => params[:page], :per_page => Mission.limit_per_page)
    if logged_in?
      latest_missions = Mission.find(:all, :conditions => [ 'minimum_level <= ?', current_user.current_level + 2 ], :limit => 200, :order => "missions.created_at DESC")
    else
      latest_missions = Mission.find(:all, :limit => 200, :order => "missions.created_at DESC")
    end
    @missions = latest_missions.paginate(:page => params[:page], :per_page => Mission.limit_per_page, :limit => 200)

    respond_to do |format|
      format.html # index.html.erb
      format.js do
        render :action => 'mission_filter.rjs'
        # render :update do |page|
        #   page.replace_html 'missions_lists', :partial => 'association_list'
        # end
      end
      format.rss { render :action => "rss.xml.builder", :layout => false }
    end
  end

  def search
    @page_title = "#{params[:q]} - Searching Missions on "
    if params[:q]
      @missions = Mission.search(params[:q], :include => [:user], :limit => 25, :order => 'missions.created_at DESC')
    end
  end

  # View by association (i.e; Shoat, Pathmaker etc;)
  def association
    @page_title = "#{params[:id].titleize} Missions on "
    @img = "/images/shared/associations/small/#{params[:id].pluralize}.jpg" # Shows the selected association img
    @heading_text = [params[:id].titleize, "/missions/association/#{params[:id]}"] # "Missions" is already included in the partial so this will be shown as "(Association name) Missions"

    if params[:id].downcase == 'shoat'
      mission_assoc = Mission.find_all_by_shoat(params, @sort, current_user, nsfw_preference  )
    else
      mission_assoc = Mission.find_all_in_association(params, @sort, current_user, nsfw_preference )
    end

    @missions = mission_assoc.paginate( :page => params[:page], :per_page => Mission.limit_per_page )

    respond_to do |format|
      format.html do
        render :template => 'missions/index'
      end
      format.js do
        render :action => 'mission_filter.rjs'
        # render :update do |page|
        #   page.replace_html 'missions_lists', :partial => 'association_list'
        #   page.replace_html 'missions_lists_header', :partial => 'index_header'
        # end
      end
    end
  end

  def user_missions
    if @user.nil?
      if params[:user_id]
        @user = User.find(params[:user_id])
      else
        @user = current_user
      end
    end

    @page_title = "#{@user.login}'s #{params[:id].titleize} Missions on "
    @heading_text = [params[:id].titleize, "/missions/user_missions/#{params[:id]}"] # "Missions" is already included in the partial so this will be shown as "(Association name) Missions"

    # Because the get data is encapsulated in the user, we have to appease the dynamic lists in the user controller
    params[:mission_type] = params[:id]
    @missions = @user.get_mission_data(params, @sort).paginate(:page => params[:page], :per_page => Mission.limit_per_page)

    respond_to do |format|
      format.html do
        render :template => 'missions/index'
      end
      format.js do
        render :action => 'mission_filter.rjs'
        # render :update do |page|
        #   page.replace_html 'missions_lists', :partial => 'association_list'
        #   page.replace_html 'missions_lists_header', :partial => 'index_header'
        # end
      end
    end
  end

  # View the highest rated missions
  def highest_rated
    @page_title = 'Top-Rated Missions on '
    @img = nil # No image associated with the latest missions
    @heading_text = ['Top-Rated', '/missions/top'] # "Missions" is already included in the partial so this will be shown as "Top-Rated Missions"

    Mission.non_pmog_missions do
      @missions = Mission.find_top(params, current_user, @sort, nsfw_preference).paginate(:page => params[:page], :per_page => Mission.limit_per_page)
    end

    respond_to do |format|
      format.html do
        render :template => 'missions/index'
      end
      format.js do
        render :action => 'mission_filter.rjs'
        # render :update do |page|
        #   page.replace_html 'missions_lists', :partial => 'association_list'
        #   page.replace_html 'missions_lists_header', :partial => 'index_header'
        # end
      end
    end
  end

  # Method call to display the current user's favorite missions
  def user_favorites
    @page_title = current_user.login + "'s Favorite Missions on "
    @img = nil # No image associated with the favorite missions
    @heading_text = ["#{current_user.login}'s Favorite", '/missions/favorites'] # "Missions" is already included in the partial so this will be shown as "<user login>'s Favorite Missions"

    @missions = current_user.favorite_missions.paginate(:page => params[:page], :per_page => Mission.limit_per_page)

    respond_to do |format|
      format.html do
        render :template => 'missions/index'
      end
      format.js do
        render :action => 'mission_filter.rjs'
        # render :update do |page|
        #   page.replace_html 'missions_lists', :partial => "association_list"
        #   page.replace_html 'missions_lists_header', :partial => 'index_header'
        # end
      end
    end

  end

  # Gets the PMOG-related missions and renders them to the mission view
  def pmog_missions
    @page_title = "The Nethernet's Missions on "
    @img = nil # No image associated with the favorite missions
    @heading_text = ["The Nethernet's", "/missions/pmog"] # "Missions" is already included in the partial so this will be shown as "PMOG-Related Missions"

    @missions = Mission.get_cache("pmog_missions_#{params[:page]}_#{@sort}") do
      Mission.pmog_missions do
        Mission.paginate( :all,
                          :order => @sort,
                          :page => params[:page],
                          :per_page => Mission.limit_per_page
                        )
      end
    end

    respond_to do |format|
      format.html do
        render :template => 'missions/index'
      end
      format.js do
        render :action => 'mission_filter.rjs'
        # render :update do |page|
        #   page.replace_html 'missions_lists', :partial => "association_list", :locals => { :heading => "The Nethernet's", :img => nil }
        #   page.replace_html 'missions_lists_header', :partial => 'index_header'
        # end
      end
    end
  end

  # The latest created missions on PMOG
  def latest
    @page_title = 'Latest Missions Created on '

    latest_missions = Mission.find(:all, :conditions => [ 'minimum_level <= ?', current_user.current_level + 2 ], :limit => 200, :order => "missions.created_at DESC")

    @missions = latest_missions.paginate(:page => params[:page], :per_page => Mission.limit_per_page)

    @heading_text = ["Latest", "/missions"]

    respond_to do |format|
      format.html do
        render :action => :index
      end
      format.js do
        render :action => 'mission_filter.rjs'
      end
    end
  end

  # Show a single mission
  def show
    @mission = Mission.find_by_url_name(params[:id])
    raise ActiveRecord::RecordNotFound if @mission.nil?

    # If the current user and the mission author are the same
    # we assume this is the author doing their test of the mission
    # during the creation of the mission and send him back there.
    if current_user == @mission.user and @mission.is_active == false
      redirect_to overview_path( @mission.url_name ) and return
    end

    # Using will_paginate makes this pretty painless
    @comments = Comment.paginate_by_commentable_id @mission.id, :page => params[:page], :include => :user, :order => 'comments.created_at DESC'

    @mission_users = @mission.users.paginate(:page => params[:user_page], :per_page => 20)

    @page_title = @mission.name + ', a Mission on '

    # Render any mission complete text, if required
    if cookies[:mission_complete_text]
      flash[:notice] = cookies[:mission_complete_text]
      cookies.delete :mission_complete_text
    end
  end

  # The view to show when the mission is ready to test
  def test
    @mission = Mission.find_with_inactive( :first, :conditions => { :url_name => params[:id] } )
    @page_title = "Test Your Mission on "
  end

  ############################################################################################
  # START SECTIONS OF MISSION DATA
  ############################################################################################

  def queued
    @user = User.find_by_login(params[:user_id])
    @missions = Mission.find(QueuedMission.find(:all, :conditions => ['user_id = ?', @user.id]).collect{|q| q.mission_id})

    respond_to do |format|
      format.html { render_component(:action => 'user_missions', :id => "queued", :params => {:user_id => @user.id}) }
      format.rss  { render :action => 'rss.xml.builder', :layout => false }
    end
  end

  def favorites
    @user = User.find_by_login(params[:user_id])
    @missions = Mission.favourites(@user)

    respond_to do |format|
      format.html { render_component(:action => 'user_missions', :id => "favorites", :params => {:user_id => @user.id}) }
      format.rss  { render :action => 'rss.xml.builder', :layout => false }
    end
  end


  # A users generated missions
  def generated
    @user = User.find( :first, :conditions => { :login => params[:user_id] }, :include => :missions )
    @missions = @user.missions(:order => 'updated_at asc')
    @page_title = @user.login + "'s Missions generated on "
    @privacy_opts = Preference.preferences.select {|k,v| v[:group] == 'privacy'}
    # Get the user preference for each privacy option. If they're all private then conceal
    # the profile
    @private_count = 0
    for opt in @privacy_opts do
      pref = @user.preferences.get opt[1][:text]
      if pref and pref.value == 'Private'
        @private_count += 1
      end
    end

    # this is where we check if all the options are private and if so, redirect to the private page.
    if @private_count == @privacy_opts.length and @user.id != current_user.id
      render :action => 'private' and return
    else
      render_component(:action => 'user_missions', :id => "generated", :params => {:user_id => @user.id})
    end
  end

  # A users taken missions
  def taken
    @user = User.find( :first, :conditions => { :login => params[:user_id] }, :include => :missions )
    @missions = @user.missions(:order => 'updated_at asc')
    @page_title = @user.login + "'s Missions taken on "
    @privacy_opts = Preference.preferences.select {|k,v| v[:group] == 'privacy'}
    # Get the user preference for each privacy option. If they're all private then conceal
    # the profile
    @private_count = 0
    for opt in @privacy_opts do
      pref = @user.preferences.get opt[1][:text]
      if pref and pref.value == 'Private'
        @private_count += 1
      end
    end

    # this is where we check if all the options are private and if so, redirect to the private page.
    if @private_count == @privacy_opts.length and @user.id != current_user.id
      render :action => 'private' and return
    end
  end


  ############################################################################################
  # START MANIPULATION OF MISSIONS
  ############################################################################################

  # We'll lump these into like actions. i.e; new and create, edit and update etc; Just to navigate more easily
  def new
    @mission = Mission.new
    @page_title = 'Create a New Mission on '
  end

  def create
    # On the create, we don't quite have a full mission... It's really only a name and a description. Here we'll create
    # the mission record with the name and description from the first form. (As well as the pmog_mission boolean). Then
    # we'll move on to the next step, which is adding lightposts to the mission.
    #
    # The boolean values of nsfw and is_active (representing published or not) will default to false. For nsfw we'll add a
    # means to change that in the final steps of creation, the is_active will be false until the author of the mission has
    # taken and successfully completed their own mission.

    @mission = Mission.new( :name         => params[:mission][:name],
                            :user         => current_user,
                            :description  => params[:mission][:description],
                            :minimum_level => params[:mission][:minimum_level])

    # Make this a PMOG mission if it is one
    @mission.pmog_mission = params[:mission][:pmog_mission]

    # Copied this out of the original mission creation. I would think we could add Shoat to the associations and not
    # have to conditionally assign it to shoat if it's null...
    @mission.association = current_user.primary_association unless current_user.primary_association.downcase == 'shoat'
    @mission.association = @mission.association.downcase unless @mission.association.nil?

    # Attempt to save this mission and redirect to the lightpost phase
    @mission.save!
    respond_to do |format|
      format.html { redirect_to show_lightposts_path(@mission.url_name) }
    end

  # If the form isn't properly filled out, then we need to go back to the new view and show the errors
  rescue ActiveRecord::RecordInvalid
    respond_to do |format|
      format.html { render :action => 'new' }
    end
  end

  def lightposts
    # Get the mission based on the provided mission url name
    @mission = Mission.find_with_inactive(:first, :conditions => { :url_name => params[:id] } )
    @page_title = "Organize the Mission: Lightposts on "
  end

  # Called from the lightposts view for saving the configured branches and descriptions
  def save_lightposts
    @mission = Mission.find_with_inactive(:first, :conditions => { :url_name => params[:id] } )
    @mission.nsfw = params[:mission][:nsfw]
    # Set saving_lightposts to true before save! so the validation of the branch count is called.
    @mission.saving_lightposts = true
    # save! to validate
    @mission.save!

    # Since we're saving the lightposts, it's the point of no return. If they remove a branch after this page, they don't
    # get the lightpost refunded.
    session[:new_lightposts] = nil

    Mission.expire_cache('all_in_groups')

    respond_to do |format|
      format.html { redirect_to mission_test_path( @mission.url_name ) }
    end

    # Catch any validation errors and if there are any, display the lightpost view with the areas
    rescue ActiveRecord::RecordInvalid
      respond_to do |format|
        format.html { render :action => 'lightposts' }
    end
  end

  # The view that is shown after a successful test.
  def overview
    @mission = Mission.find_with_inactive( :first, :conditions => { :url_name => params[:id] } )
    @page_title = "Review and Publish the Mission on "
  end

  # Ajax-called method for adding lightposts to a mission
  def add_lightpost
    @mission = Mission.find_with_inactive(:first, :conditions => {:url_name => params[:lightposts][:id]})

    # A new lightpost
    if params[:id] == 'create_lightpost'
      # Create a session store to hold newly created lightposts. If the user makes new lightposts,
      # We'll track them so that if they remove it, we can award the lightpost back to their inventory...
      session[:new_lightposts] = [] if session[:new_lightposts].nil?

      url = Url.normalise(params[:lightposts][:location_url])

      # Check we can use this url
      if Url.unsupported_format? url
        flash[:notice] = 'Sorry, we do not support missions on certain urls'
        redirect_to :action => 'lightposts'
        return
      end

      @location = Location.find_or_create_by_url(url)

      current_user.inventory.withdraw :lightposts
      current_user.tool_uses.reward :lightposts
      @post = current_user.lightposts.create( :location_id => @location.id )
      session[:new_lightposts] << @post.id
    # An old lightpost
    elsif params[:id] == 'add_lightpost'

      @location = Location.find(params[:lightposts][:location_id])
      @post = current_user.lightposts.find(:first, :conditions => { :location_id => params[:lightposts][:location_id]})
      branch_description = @post.description unless @post.description.blank? or @post.description.empty?
    end

    branch_description = "Please enter a description for this lightpost" if branch_description.nil? or branch_description.empty?

    @mission.branches.each do |branch|
      if branch.location == @location
        flash[:error] = "That lightpost already exists in this mission"
        redirect_to show_lightposts_path(@mission.url_name) and return
      end
    end

    if @mission.branches.nil? or @mission.branches.empty?
      @mission.branches = []
    end

    @branch = Branch.new(:location_id => @location.id)
    @branch.user        = current_user
    @branch.mission     = @mission
    @branch.description = branch_description
    @branch.save

    @branch.clone_puzzle @post unless @post.puzzle.nil?

    insert_position = @mission.branches.size == 0 ? 1 : @mission.branches.last.position + 1
    @branch.insert_at(insert_position)

    @mission.branches << @branch

    # Here we check to see if the mission is published and if so, unpublish it since we're adding a new
    # lightpost. This alters the mission altogether and could cause it to break so we need to force the
    # author to test again.
    check_published(@mission)

    @mission.save

  end

  def add_tag
    begin
      @mission = Mission.find_by_url_name(params[:id])
      new_tags = params[:tag][:name].split(",")
      @mission.tag_list.add(new_tags)
      @mission.save
      @new_tag = @mission.reload.tags.last
      total_pings = Ping.value('Reply') * new_tags.length
      current_user.reward_pings(total_pings)
      current_user.reward_datapoints(1)
    rescue ActiveRecord::HasManyThroughCantAssociateNewRecords
      render :update do |page|
        page.replace_html "tag_error", "Invalid Tag Entered"
        page.visual_effect :appear, "tag_error"
        page.visual_effect :shake, "tag_name"
        page.visual_effect :fade, "tag_error", :duration => 5.0
      end
    end
  end

  def remove_tag
    @mission = Mission.find_by_url_name(params[:id])
    @tag_to_delete = @mission.tags.find(params[:tag_id])
    if @tag_to_delete
      current_user.reward_datapoints(1)
      @mission.tags.delete(@tag_to_delete)

      # The mission cached_tag_list doens't update automatically, so let's do that here - duncan 3/4/09
      @mission.cached_tag_list = @mission.tags.collect{ |t| t.name }.join(', ')
      @mission.save
    else
      render :nothing => true
    end
  end

  # Ajax-called method for removing lightposts from a mission
  def remove_lightpost
    @branch = Branch.find(params[:id])

    if @branch
      @mission = Mission.find_with_inactive(@branch.mission_id)
      # We have to check if the lightpost being removed is in the user's list of new
      # lightposts, and if it is, then we need to give them back the lightpost they spent
      # to create it.
      location = @branch.location

      # After we get the location of the branch, we can get the lightpost associated with that location...
      lightpost = Lightpost.find_by_location_id(location.id)

      # If this was a new lightpost created for the mission and they're removing it, we delete the created
      # lightpost, remove it from our session store and give the user back their lightpost
      if !session[:new_lightposts].nil? and session[:new_lightposts].include? lightpost.id
        lightpost.destroy
        session[:new_lightposts].delete(lightpost.id)
        current_user.inventory.deposit :lightposts
      end

      # Then we destroy the branch which is what they really deleted.
      @branch.destroy

      check_published(@mission)

    else
      render :nothing => true
    end
  end

  def order
    @mission = Mission.find_with_inactive(:first, :conditions => { :url_name => params[:id] })
    params[:branches].each_with_index do |id, position|
      # To make a long story short, we're using jQuery on the site and when it serializes the branch Ids, it
      # allows you to have underscores, hyphens or equal signs. Since we use UUIDs it only returns the last portion
      # of the UUID and thus prohibits us from finding the branches to update.
      #
      # So I changed the extension to convert the hyphens in the UUID of the branch to be + (plus) signs, which get
      # turned into spaces when they post. So here we need to convert those spaces to hyphens to get the proper ID.
      Branch.update(id.gsub(" ", "-"), :position => position + 1)
    end
    @mission.save

    @branches = @mission.branches

    check_published(@mission)
  end


  # Instantly makes the mission nsfw/sfw (used by trustees)
  def toggle_nsfw
    @mission = Mission.find( :first, :conditions => { :url_name => params[:id] } )
    @mission.nsfw = params[:nsfw]
    @mission.save
  end

  def edit
    @page_title = 'Edit a Mission on '
    @mission = Mission.find_with_inactive( :first, :conditions => { :url_name => params[:id] } )
  end

  def update
    @mission = Mission.find_with_inactive( :first, :conditions => { :url_name => params[:id] } )
    @mission.update_attributes( params[:mission] )

      # Update the pmog_mission flag
      @mission.pmog_mission = params[:mission][:pmog_mission]

      @mission.save!

      respond_to do |format|
        format.html { redirect_to show_lightposts_path(@mission.url_name) }
      end

      # If the form isn't properly filled out, then we need to go back to the new view and show the errors
      rescue ActiveRecord::RecordInvalid
        respond_to do |format|
          format.html { render :action => 'edit' }
        end
  end

  # Publish a new mission draft
  def publish
    @mission = Mission.find_with_inactive(:first, :conditions => { :url_name => params[:id] } )

    # Only publish if the mission is tested by the author and the person submitting the proposal to publish is the author
    if @mission.user == current_user or site_admin?
      # Set the published flag on the mission
      @mission.publish

      # Per http://pmog.devjavu.com/ticket/1240 we're setting the mission rating to the current user's rating
      # Per http://hospital.thenethernet.com:8080/browse/WEB-756 we're disabling this.
      #@mission.average_rating = current_user.average_rating

      @mission.save

      # BirchBot.instance.say("#{current_user.login} just published a mission #{mission_url(@mission)}")

      Event.record :context => 'mission_published',
        :user_id => current_user.id,
        :message => 'just published a mission called <a href="' + mission_url(@mission) + '">' + @mission.name + '</a>'

    else
      render :action => 'overview'
      return
    end

    respond_to do |format|
      format.html { redirect_to mission_path(@mission.url_name) + '#share' }
    end
  end

  def unpublish
    @mission = Mission.find_with_inactive(:first, :conditions => { :url_name => params[:id] } )

    @mission.unpublish

    @mission.save

    Mission.expire_cache('all_in_groups')

    respond_to do |format|
      format.js
    end
  end

  # Method used by the in-place editor to edit the mission name
  def set_name
    @mission = Mission.find(:first, :conditions => { :url_name => params[:id] } )
    @mission.name = params[:value]
    @mission.save
    Mission.expire_cache('all_in_groups')
    render :text => @mission.name
  end

  # Method used by the in-place editor to edit the mission description
  def set_description
    @mission = Mission.find(:first, :conditions => { :url_name => params[:id] } )
    @mission.description = params[:value]
    @mission.save
    Mission.expire_cache('all_in_groups')
    render :text => @mission.description
  end

  ############################################################################################
  # ACT ON MISSIONS
  ############################################################################################

  # Just setup the user session and redirect the user. Called by an overlay.
  # If we want, we can do more things here, but for now this is all.
  def take
    @mission = Mission.find_with_inactive( :first, :conditions => { :url_name => params[:id] }, :include => :branches, :order => 'branches.position ASC' )

    if @mission.nsfw and ! current_user.allow_nsfw?
      flash[:notice] = 'You have opted not to take NSFW missions'
      redirect_to '/missions'
    else
      @mission.takers << current_user
      session[:mission_id] = @mission.id
      session[:mission_locations] = []
      redirect_to @mission.branches.first.location.url
    end
  end

  def abandon
    clear_session

    respond_to do |format|
      flash[:notice] = "Mission has been abandoned. You'll need to start from the beginning to complete it."
      format.json {
        render :json => render_full_json_response(:flash => flash), :status => 201
        flash.discard
      }
    end
  end

  # POST /missions/mission_url_name/guess
  def guess
    begin
      @branch = Branch.find(params[:branch_id])
    rescue ActiveRecord::RecordNotFound
      flash[:error] = "Lightpost not found!"
      send_full_lightpost_response :flash => flash
      flash.discard
    end

    if params[:skeleton_key].to_bool
      if current_user.inventory.skeleton_keys >= 1
        current_user.inventory.withdraw :skeleton_keys
        current_user.tool_uses.reward :skeleton_keys

        next_url = white_list(@branch.next.location.url) if !@branch.next.nil?
        respond_to do |format|
          format.json {
            render :json => {:next_url => next_url}.to_json, :status => 200
          }
        end
      else
        flash[:error] = "You have no Skeleton Keys!"
        send_full_lightpost_response :flash => flash
        flash.discard
        return
      end
    elsif @branch.solve_puzzle params[:answer]
      next_url = white_list(@branch.next.location.url) if !@branch.next.nil?
      respond_to do |format|
        format.json {
          render :json => {:next_url => next_url}.to_json, :status => 200
        }
      end
    else
      flash[:error] = "Wrong answer!"
      send_full_lightpost_response :flash => flash
      flash.discard
    end
  end

  # POST /missions/mission_url_name/complete
  def complete
    begin
      # Hmm, let's see if this fixes the random 500s on mission completion.
      # My hunch is that it's caused by GETs not POSTs to this url. It's either
      # that, or I'm just walking funny....
      raise Exceptions::MissionCompleteError.new('Completing the mission failed, please go back and try again!') unless request.post?
        #flash[:notice] = 'Completing the mission failed, please go back and try again!'
        #redirect_to :action => 'index' and return

      #end

      @mission = Mission.find_with_inactive(session[:mission_id])

      # Send phonies back to the index
      # To complete a mission, the users session must containt each of the branches
      # This is an attempt to stop someone POSTing to this url and completing the
      # mission without taking it. It's not a huge problem, but we should try
      # *Something* to deter it...
      # if session[:mission_locations].size < @mission.branches.count
      #   flash[:notice] = 'Something went wrong, sorry!'
      #   redirect_to :action => 'index'
      #   return
      # end
      #raise Exceptions::MissionCompleteError.new('Something went wrong, please click the "Previous" button and try again.') if session[:mission_locations].size < @mission.branches.count

      # Dish out the standard rewards
      # Note that we store the relevant success message in flash and a cookie, since the extension
      # is not rendering anything from this page, so we need to make sure users know they've completed a mission - duncan 29/09/08
      @mission.reward_creator(current_user)
      # And the possible other rewards
      rewardsblurb = 'Mission complete!'
      MissionShare.fulfill_any_for(current_user, @mission).each do |ms|
        rewardsblurb += "<br>#{ms.sender.login} gave you #{ms.reward} datapoints for completing this mission." if ms.reward > 0
      end
      flash[:notice] = rewardsblurb
      cookies[:mission_complete_text] = rewardsblurb

      clear_session

      # Add the current user to the mission history first, so if
      # the author and the user are the same, we can redirect immediately.
      unless @mission.users.include? current_user
        @mission.users << current_user
        current_user.expire_cache( "completed_missions_#{current_user.id}" )
      end

      # Remove the record from the taking table so we don't count it as a non-ending mission
      @mission.takers.delete(current_user)

      # Remove it from the user's queue if it's queued
      # Then clear the users queued mission cache
      QueuedMission.dequeue(current_user, @mission)
      current_user.expire_cache( "queued_missions" )
      current_user.expire_cache(:missions_queued)
      current_user.expire_cache('queued_missions_list')

      Event.record :context => 'mission_completed',
        :user_id => current_user.id,
        :recipient_id => @mission.user.id,
        :message => " just completed a Mission: <a href=\"#{@mission.pmog_host}/missions/#{@mission.url_name}\">#{@mission.name}</a>"

      respond_to do |format|
        format.json {
          render :json => render_full_json_response(:flash => flash), :status => 201
          flash.discard
        }
      end
    rescue Exceptions::MissionCompleteError => e
      flash[:error] = e.message
      respond_to do |format|
        format.json {
          render :json => render_full_json_response(:flash => flash), :status => 422
          flash.discard
        }
      end
    end
  end

  def destroy
    @mission = Mission.find_with_inactive( :first, :conditions => { :url_name => params[:id] } )
    redirect_to missions_path() unless @mission.user == current_user or site_admin?

    if @mission
      @mission.destroy
      Mission.expire_cache('all_in_groups')
      flash[:notice] = "Mission was successfully deleted"
      redirect_to missions_path
    end
  end

  # POST /missions/id/dismiss.js
  # Dismiss this overlay, so that the user doesn't see it again
  def dismiss
    @mission = Mission.find_with_inactive(params[:id])

    # Dismiss the mission
    @mission.dismiss(current_user)

    flash[:notice] = "Mission dismissed!"
    respond_to do |format|
      format.json {
        response.headers["Content-Type"] = "text/json; charset=utf-8"
        render :json => flash.to_json, :status => 201
        flash.discard
      }
      format.js { render :json => create_overlay(@mission, :template => 'missions/dismiss', :window_id => @window_id) }
    end
  end

  def vote
    @mission = Mission.find(params[:id])
    # Since we're not looking for yea or nay, only "this is nsfw"
    # we'll specify true up front
    new_vote = Vote.new(:vote => true, :user_id => current_user.id)
    @mission.votes << new_vote

    # If the number of votes for a mission is >= 3, flag it as nsfw
    if @mission.votes_count >= 3
      @mission.nsfw = true
    end

    render :update do |page|
      page.replace_html "vote", "<p style=\"color:green; font-weight:bold;\">Added your vote to: #{@mission.name}</p>"
      page[:vote].visual_effect :pulsate, :duration => 5, :queue => {:position => 'end', :scope => 'vote'}
      page[:vote].visual_effect :fade, :duration => 1, :queue => {:position => 'end', :scope => 'vote'}
    end
  end

  def favorite
    @mission = Mission.find(params[:id])
    @view = params[:view]
    flash[:notice] = "Added to favorites!"
    current_user.favorite! @mission
    current_user.expire_cache(:all_favorites)

    respond_to do |format|
      format.js { render :action => 'favorite.rjs' }
    end
  end

  def unfavorite
    @user = User.find(params[:user_id])
    @mission = Mission.find(params[:id])
    @favorite = @user.favorites.find_by_favorable_id(@mission.id)
    @view = params[:view]
    flash[:notice] = "Removed from favorites!"

    @user.favorites.delete(@favorite)
    @user.expire_cache(:all_favorites)

    respond_to do |format|
      format.js { render :action => 'favorite.rjs' }
    end

  end

  def queue
    @mission = Mission.find(params[:id])
    @view = params[:view]
    current_user.missions_queued << @mission
    current_user.expire_cache( "queued_missions" )
    current_user.expire_cache(:missions_queued)
    current_user.expire_cache('queued_missions_list')
    flash[:notice] = 'Mission queued for later'

    respond_to do |format|
      format.js { render :action => 'queue.rjs' }
    end

  end

  def dequeue
    @mission = Mission.find(params[:id])
    @view = params[:view]

    current_user.missions_queued.delete(@mission)
    current_user.expire_cache( "queued_missions" )
    current_user.expire_cache(:missions_queued)
    current_user.expire_cache('queued_missions_list')
    flash[:notice] = 'Mission removed from queue'

    respond_to do |format|
      format.js { render :action => 'queue.rjs' }
    end

  end

  def share
    @mission = Mission.find_by_url_name(params[:id])

    params[:recipients].split("\r\n").each do |eml|
      MissionShare.create(:sender => current_user, :recipient => eml,
        :mission => @mission, :reward => params[:reward_dps].to_i)
      current_user.deduct_datapoints(2)
    end

    flash[:notice] = 'Mission shared'
    redirect_to :action => 'show'
  end

  # Handles searching for missions based on content of specific parameters
  # def search
  #   if params[:q]
  #     @missions = Mission.find_by_contents(params[:q], :lazy => [:name, :description, :author_name], :page => params[:page], :per_page => 10)
  #     @heading_text = ["Search for #{params[:q]} yielded #{@missions.total_hits}", "/missions/search?q=#{params[:q]}"]
  #
  #   else
  #     @missions = []
  #     @heading_text = ["Search", "/missions/search"]
  #   end
  #   render :template => "missions/index"
  # end

  # Record some stats on Missions
  # - runs as an after_filter so that we have access to @mission
  # - only stumbled missions for now
  # - everything else we need should be in the query string
  def record_stats
    MissionStat.record(current_user, @mission, params)
  end

  def nsfw_preference
    nsfw = false
    unless !logged_in?
      nsfw = current_user.preferences.setting('Allow NSFW')
    end
    return nsfw
  end
  private :nsfw_preference

  def can_edit?
    @mission = Mission.find_with_inactive(:first, :conditions => ['url_name = ?', params[:id]])
   redirect_to missions_path() unless @mission.user == current_user or site_admin?
  end
  private :can_edit?

  def sort_param
    @sort = case params['sort']
              when "date"             then "missions.created_at"
              when "rating"           then "missions.average_rating"
              when "date_reverse"     then "missions.created_at DESC"
              when "rating_reverse"   then "missions.average_rating DESC"
              else                          "missions.created_at DESC"
            end
  end
  private :sort_param

  protected

  def send_full_lightpost_response data, status=422
    respond_to do |format|
      format.json {
        render :json => render_full_json_response(data), :status => status
      }
    end
  end

  # Keep track of the lightpost descriptions when building a mission
  def add_descriptions_to_session(params)
    # Keep track of the descriptions, too
    session[:mission_lightposts].each do |lightpost|
      session[:lightpost_descriptions][lightpost.to_sym] = params[lightpost.to_sym] if params[lightpost.to_sym]
    end
  end

  # Call this when editing a mission or adding/removing to force the author to test the changes.
  def check_published(mission)
    @unpublished = false
    if mission.is_active?
      mission.unpublish
      mission.save
      @unpublished = true
    end
    # Clear the mission cache to keep it synchronized and prevent errors
    @mission.clear_cache
    @mission.branches.each do |b|
      b.clear_cache
    end
  end

  def clear_session
    # Clear the session
    session[:mission_id] = nil
    session[:mission_locations] = nil
    session[:mission_lightposts] = nil
    session[:lightpost_descriptions] = nil
  end

  def check_inactive_mission
     @mission = Mission.find_by_url_name(params[:id])

     if @mission.nil?
       flash[:error] = "That mission doesn't exist"
       redirect_to missions_path
     elsif not @mission.is_active?
       unless site_admin? or steward? or current_user == @mission.user
         flash[:error] = "That mission isn't ready for showtime"
         redirect_to missions_path
       end
     end
  end
end
