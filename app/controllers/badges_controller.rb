class BadgesController < ApplicationController
  before_filter :login_required

  # The default action and associated view for the badges model
  def index
    # The badge index is designed to show the earned badges for a user that is provided as a url parameter.
    # If it's nil (i.e not provided), then we set it to the current users badges
    if params[:user_id].nil?
      @user = current_user
    else
      @user = User.find( :first, :conditions => { :login => params[:user_id] } )
    end
    @badges = Badge.find(:all)
    @page_title = @user.login + '\'s badges on '

    respond_to do |format|
      format.html
      format.rss { render :template => 'badges/index.rss.builder', :layout => false }
    end
  end

  # Lists all the existing badges.
  def list
    # If the current logged in user isn't an admin, then redirect to the home index and flash an error.
    # Because we allow admins to administer groups via the list view
    if !site_admin?
      flash[:error] = 'You don\'t have the credentials to view that page'
      redirect_to :controller => 'home'
    # Otherwise, get all the badges and supply it to the view
    else
      @badges = Badge.find(:all)
      @page_title = 'Listing all badges on '
    end
    # The groups are for assigning each badge to a group.
    @groups = Group.find(:all)
  end

  # The action called by the in-place select editor on the badge group value
  def set_badges_group_id
    # Because we're using UUIDs and not Auto-increment integers, the in place editor javascript
    # turns the UUID string into an integer which we don't understand. to work around this, I've
    # set it up to include the badge UUID in the editorId parameter. This parses the UUID out of the
    # editorId which looks like this: badges_group_id_898033f4-e947-11dc-a035-001b63928f8d_in_place_editor
    # So, we split on the underscore (_) and get the 3rd string in the resulting string array
    badge_id = params[:editorId].split('_')[3]
    # Then we take that id and get the Badge object it represents
    @badge = Badge.find_by_id(badge_id)
    # The group_id is the value of the select box in the in place select editor
    @group = Group.find_by_id(params[:value])
    # Set the badge.group_id to the group selected
    @badge.group_id = params[:value]
    # Save the badge record
    @badge.save
    # Now show the name of the newly assigned group
    render :text => @group.name
  end

  # Not really needed, but some people know RoR and might try some funny stuff
  # So we'll redirect on the common actions that we don't employ
  def show
    redirect_to :action => :index
  end

  # Same as the show action above
  def edit
    redirect_to :action => :index
  end
end
