class CratesController < ApplicationController
  before_filter :login_required
  ##before_filter :authenticate, :only => :list
  permit 'site_admin', :only => [ :list, :search, :destroy ]

  # GET /location/location_id/crate
  # Um, this should really be /location/location_id/crates/new.js
  def index
    @page_title = 'Crates overview on '

    # # Zomg hack...
    if params[:location_id]
      if current_user.inventory.crates == 0
        flash[:notice] = 'You need to purchase more crates!'
        redirect_to( :controller => 'shoppe', :action => 'index' ) and return
      end

      @location = Location.find( :first, :conditions => { :id => params[:location_id] } )
      @page_title = 'Deploy a Crate from your Stash using '

      respond_to do |format|
        format.html
      end
    elsif site_admin?
      list
      render :action => 'list'
    else
      redirect_to :controller => 'session', :action => 'new'
    end
  end

  # GET /location/location_id/crates/new
  def new
    if current_user.inventory.crates == 0
      flash[:notice] = 'You need to purchase more crates!'
      redirect_to( :controller => 'shoppe', :action => 'index' ) and return
    end

    @location = Location.find( :first, :conditions => { :id => params[:location_id] }, :include => [ :crates ], :group => 'crates.id' )
    @page_title = 'Deploy a Crate from your Stash on '

    # So that we can display a notice that any crate deployed on a
    # user profile page will be sekrit
    @profile_user = @location.check_for_pmog_profile_page

    respond_to do |format|
      format.html
    end
  end

  def list
    return unless site_admin?

    @crates = Crate.paginate( :all,
                              :order => 'crates.created_at DESC',
                              :page => params[:page],
                              :per_page => 100 )
  end

  def search
    return unless site_admin?

    case params[:criteria]
    when "location"
      @crates = Crate.paginate(:all, :include => [:user, :location], :conditions => ['crates.location_id = locations.id and locations.url = ?', params[:q]], :page => params[:page], :per_page => 100, :order => "crates.created_at DESC")
      @page_title = "Crates on location -- #{params[:q]}"
      @h1content = "Crates on #{params[:q]}"
    when "user"
      @searcheduser = User.find_by_login(params[:q])
      @crates = Crate.paginate(:all, :include => [:user, :location], :conditions => ['crates.user_id = ?', @searcheduser.id], :order => "crates.created_at DESC", :page => params[:page], :per_page => 100)
      @page_title = "User #{params[:q]}'s crates "
      @h1content = "#{params[:q]}'s Crates"
    end


    #@searcheduser = User.find_by_login(params[:q])
    #@crates = Crate.paginate(:all,
    #                            :conditions => ['crates.user_id = ?', @searcheduser.id],
    #                            :order => "crates.created_at DESC",
    #                            :page => params[:page],
    #                            :per_page => 100 )
    #@page_title = "#{@searcheduser.login}'s Crates on "
  end

  def create
    @location = Location.find(params[:location_id])
    begin

      @crate = Crate.create_and_deposit(current_user, @location, params)

      respond_to do |format|
        flash[:notice] = "Crate stashed!"
        format.html { render :action => 'deployed' }
        format.json {
          response.headers["Content-Type"] = "text/json; charset=utf-8"
          render :json => render_full_json_response(:flash => flash), :status => 201
          flash.discard
        }
      end
    rescue PMOG::PMOGError => e
      handle_crate_error(e.message)
    rescue Exception => e
      log_exception(e)
      handle_crate_error("A system error has occured, please try again later.")
    end
  end

  # PUT /location/location_id/crates/id/loot.js
  # Take all items from a crate and award class points to the crate creator
  def loot
    Crate.transaction do
      params[:avatar_path] = "#{host}#{avatar_path_for_user(:user => current_user, :size => "tiny")}"

      begin
        @crate = Crate.find(params[:id])
      rescue ActiveRecord::RecordNotFound => e
        handle_crate_error("Sorry, we couldn't find the crate you were looking for.  Perhaps it was already looted?", 401)
        return
      end

      begin
        @contents = @crate.loot(current_user, params)
      rescue Crate::CrateError => e
        handle_crate_error(e.message, 401)
        return
      end
    end
    @contents[:flash] = "Crate looted"

    render_loot_response(@contents)
  rescue Crate::CrateLootError => e
    handle_crate_error(e.message, 401)
  rescue Exception => e
    log_exception(e)
    handle_crate_error("Sorry, there was a problem with that crate",404)
  end

# DISABLED 09-02-05 by alex as part of the inventory overhaul.  if you want it back send me a ticket but i'm ignoring for now since its unused.

#  # PUT /location/location_id/crates/id/deposit.js
#  # To allow any user to put a tool or datapoints into a crate, currently unused
#  def deposit
#    return 'Not implemented yet' unless site_admin?
#
#    @crate = Crate.find(params[:id], :include => [ :user, :location, :inventory ], :group => 'crates.id')
#    @crate.inventory.deposit(current_user, :crate_id => params[:id], :datapoints => params[:crate][:datapoints], :tool => params[:crate][:tool] )
#
#    respond_to do |format|
#      if @crate.save
#        format.js { render :json => @crate.to_json }
#      else
#        format.js { render :json => 'Failed to update crate'.to_json }
#      end
#    end
#  end
#
#  # PUT /location/location_id/crates/id/withdraw.js
#  # To allow any user to remove individual tools or datapoints from a crate, currently unused
#  def withdraw
#    return 'Not implemented yet' unless site_admin?
#
#    @crate = Crate.find(params[:id], :include => [ :user, :location, :inventory ], :group => 'crates.id')
#    @crate.inventory.withdraw(current_user, params)
#
#    respond_to do |format|
#      if @crate.save
#        format.js { render :json => @crate.to_json }
#      else
#        format.js { render :json => 'Failed to update crate'.to_json }
#      end
#    end
#  end

  # DELETE /location/location_id/crates/1.js
  def destroy
    if ! params[:delete_these].blank?
      Crate.destroy(params[:delete_these])

      flash[:notice] = 'Crates destroyed'
      redirect_to :action => 'index'
    else
      @crate = Crate.find(params[:id])
      @crate.destroy

      flash[:notice] = 'Crate destroyed'
      redirect_to :action => 'index'
    end
  end

  # POST /locations/location_id/crates/id/dismiss.js
  # Dismiss this overlay, so that the user doesn't see it again
  def dismiss
    begin
      @crate = Crate.find(params[:id])
      @window_id = params[:window_id].nil? ? @crate.id : params[:window_id]
      @crate.dismissals.dismiss current_user unless @crate.dismissals.dismissed_by? current_user

      flash[:notice] = "Crate dismissed!"
      respond_to do |format|
        format.json {
          response.headers["Content-Type"] = "text/json; charset=utf-8"
          render :json => render_full_json_response(:flash => flash), :status => 201
          flash.discard
        }
      end
    rescue Exception => e
      flash[:error] = "Unable to dismiss this crate. Please try again later"
      respond_to do |format|
        format.json {
          response.headers["Content-Type"] = "text/json; charset=utf-8"
          render :json => render_full_json_response(:flash => flash), :status => 422
          flash.discard
        }
      end
    end
  end

  protected
  def render_loot_response(contents, status = 201)
    respond_to do |format|
      format.json do
        render :json => render_full_json_response(:crate_contents => contents), :status => status
      end
    end
  end

  private
  def handle_crate_error(msg, status = 422)
    flash[:error] = msg
    respond_to do |format|
      format.html do
        @page_title = 'Deploy a Crate from your Stash on '
        render :action => :index
      end
      format.json do
        response.headers["Content-Type"] = "text/json; charset=utf-8"
        render :json => render_full_json_response(:flash => flash), :status => status
        flash.discard
      end
    end
  end
end
