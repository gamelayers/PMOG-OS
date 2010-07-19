class PortalsController < ApplicationController
  before_filter :login_required
  before_filter :find_portal, :only => [:take, :dismiss, :rate, :vote]
  ##before_filter :authenticate, :only => :index
  permit 'site_admin or steward', :only => [ :index, :search, :destroy ]

  # GET /portals
  def index
    @portals = Portal.paginate( :all,
                                :order => "portals.created_at DESC",
                                :page => params[:page],
                                :per_page => 100 )
    @page_title = "Portal Overview on "
  end

  # GET /portals/search
  def search
    case params[:criteria]
    when "location"
      @portals = Portal.paginate(:all, :include => [:user, :location], :conditions => ['portals.location_id = locations.id and locations.url = ?', params[:q]], :page => params[:page], :per_page => 100, :order => "portals.created_at DESC")
      @page_title = "Portals on location -- #{params[:q]}"
      @h1content = "Portals on #{params[:q]}"
    when "user"
      @searcheduser = User.find_by_login(params[:q])
      @portals = Portal.paginate(:all, :include => [:user, :location], :conditions => ['portals.user_id = ?', @searcheduser.id], :order => "portals.created_at DESC", :page => params[:page], :per_page => 100)
      @page_title = "User #{params[:q]}'s Portals on "
      @h1content = "#{params[:q]}'s Portals"
    when "destination"
      @portals = Portal.paginate(:all, :include => [:user, :location], :conditions => ['portals.destination_id = locations.id and locations.url = ?', params[:q]], :order => "portals.created_at DESC", :page => params[:page], :per_page => 100)
      @page_title = "Portals on destination -- #{params[:q]}"
      @h1content = "Portals on Destination #{params[:q]}"
    end
  end

  # GET /portals/new.js
  def new
    @portal = Portal.new
    @location = Location.find(params[:location_id])
    @window_id = Time.now.to_i
    respond_to do |format|
      format.json { render :json => create_overlay(@portal, :template => 'portals/new') }
      format.js { render :json => create_overlay(@portal, :template => 'portals/new') }
    end
  end

  # POST /locations/location_id/portals.js
  def create
    @deployed_portal = Portal.create_and_deposit(current_user, params)
    respond_to do |format|
      format.json {
        flash[:notice] = "Success! Portal drawn with #{@deployed_portal.charges} charges."
        response.headers["Content-Type"] = "text/json; charset=utf-8"
        render :json => render_full_json_response(:flash => flash), :status => 201
        flash.discard
      }
    end
  rescue PMOG::PMOGError, Exception => e
    flash[:error] = e.message
    respond_to do |format|
      format.html { render :action => :index }
      format.json {
        response.headers["Content-Type"] = "text/json; charset=utf-8"
        render :json => render_full_json_response(:flash => flash), :status => 422
        flash.discard
      }
    end
  end

  # GET /portals/jaunt.json
  def jaunt
    @portal = Portal.find_first_random_and_appropriate_for(current_user)
    raise ActiveRecord::RecordNotFound unless @portal
    Portal.record_jaunt(current_user)

    # Send a redirect, just in case
    respond_to do |format|
      format.json { render :json => render_full_json_response(:portals => [@portal.to_json_overlay(:type => 'portal')]), :status => 200 }
    end
  rescue ActiveRecord::RecordNotFound
    flash[:error] = "Unable to find portal. Please try again later"
    respond_to do |format|
      format.json do
        response.headers["Content-Type"] = "text/json; charset=utf-8"
        render :json => render_full_json_response(:flash => flash), :status => 422
        flash.discard
      end
    end
  end

  # GET /locations/location_id/portals/id/take.json
  # Add this user to the list of portal users and track them so we can ask for a rating
  def take
    store_portal_id

    # Send a redirect, just in case
    respond_to do |format|
      format.html { redirect_to @portal.destination.url }
      format.json {
        response.headers["Content-Type"] = "text/json; charset=utf-8"
        render :json => {}, :status => '200'
      }
    end
  end

  # POST /locations/location_id/portals/id/dismiss.js
  # Dismiss this overlay, so that the user doesn't see it again
  def dismiss
    begin
      @window_id = params[:window_id].nil? ? @portal.id : params[:window_id]
      @portal.dismissals.dismiss current_user unless @portal.dismissals.dismissed_by? current_user

      # Register a vote of 1 star if a user dismisses a portal. This is to reduce portal spam. See http://pmog.devjavu.com/ticket/1130
      @portal.rate(current_user, 1)

      flash[:notice] = "Portal dismissed!"
      respond_to do |format|
        format.json {
          response.headers["Content-Type"] = "text/json; charset=utf-8"
          render :json => render_full_json_response(:flash => flash), :status => 201
          flash.discard
        }
      end
    rescue Exception => e
      flash[:error] = "Unable to dismiss this portal. Please try again later"
      respond_to do |format|
        format.json {
          response.headers["Content-Type"] = "text/json; charset=utf-8"
          render :json => render_full_json_response(:flash => flash), :status => 422
          flash.discard
        }
      end
    end
  end

  # POST /locations/location_id/portals/id/rate.js
  # Rate the portal, if the user hasn't done so already, and update the average rating
  def rate
    @window_id = params[:window_id].nil? ? @portal.id : params[:window_id]
    @portal.rate(current_user.id, params[:portal][:rating]) if params[:portal] && params[:portal][:rating]
    current_user.reward_pings Ping.value("Rating")
    flash[:notice] = "Portal rated!"
    respond_to do |format|
      format.json do
        response.headers["Content-Type"] = "text/json; charset=utf-8"
        render :json => render_full_json_response(:flash => flash), :status => 201
        flash.discard
      end
    end
  end

  def vote
    # Since we're not looking for yea or nay, only "this is nsfw" we'll specify true up front
    new_vote = Vote.new(:vote => true, :user_id => current_user.id)
    @portal.votes << new_vote

    # If the number of votes for a mission is >= 3, flag it as nsfw
    if @portal.votes_count >= 3
      @portal.nsfw = true
      @portal.save
    end

    respond_to do |format|
      format.json { render :json => create_overlay(@portal, :template => 'portals/voted') }
    end
  end

  # DELETE /portals/1.js
  def destroy
    if ! params[:delete_these].blank?
      Portal.destroy(params[:delete_these])

      flash[:notice] = 'Portals destroyed'
      redirect_to :action => 'index'
    else
      @portal = Portal.find(params[:id])
      @portal.destroy

      flash[:notice] = 'Portal destroyed'
      redirect_to :action => 'index'
    end
  end

  protected
  def store_portal_id
    # Store the id as a cookie and session var so that we can rate it afterwards
    # Note that the cookie/session thing is for reliablility, we've seen some session problems
    cookies[:portal_id] = @portal.id
    session[:portal_id] = @portal.id
    @portal.transport(current_user)
  end

  def find_portal
    @portal = Portal.find(params[:id])

  rescue ActiveRecord::RecordNotFound => e
    flash[:error] = "Unable to find portal. Please try again later"
    respond_to do |format|
      format.json do
        response.headers["Content-Type"] = "text/json; charset=utf-8"
        render :json => render_full_json_response(:flash => flash), :status => 422
        flash.discard
      end
      format.html { redirect_to home_url}
    end
  end
end
