class MinesController < ApplicationController
  before_filter :login_required
  ##before_filter :authenticate, :only => :index
  permit 'site_admin', :only => [ :index, :search, :destroy ]

  # GET /mines
  def index
    @mines = Mine.paginate( :all,
                            :order => 'mines.created_at DESC',
                            :page => params[:page],
                            :per_page => 100 )
    @page_title = 'Mine Overview on '
  end

  # GET /mines/search
  def search
    case params[:criteria]
    when "location"
      @mines = Mine.paginate(:all, :include => [:user, :location], :conditions => ['mines.location_id = locations.id and locations.url = ?', params[:q]], :page => params[:page], :per_page => 100, :order => "mines.created_at DESC")
      @page_title = "Mines on location -- #{params[:q]}"
      @h1content = "Mines on #{params[:q]}"
    when "user"
      @searcheduser = User.find_by_login(params[:q])
      @mines = Mine.paginate(:all, :include => [:user, :location], :conditions => ['mines.user_id = ?', @searcheduser.id], :order => "mines.created_at DESC", :page => params[:page], :per_page => 100)
      @page_title = "User #{params[:q]}'s mines "
      @h1content = "#{params[:q]}'s Mines"
    end
  end

  # POST /location/location_id/mines.js
  # Take a mine from your inventory and put it down here
  def create
    params[:avatar_path] = "#{host}#{avatar_path_for_user(:user => current_user, :size => "tiny")}"
    @deployed_mine, @message = Mine.create_and_deposit(current_user, params)
    flash[:notice] = @message
    render_create_response(flash, 201)
  rescue PMOG::PMOGError => e
    flash[:error] = e.message
    render_create_response(flash, 422)
  rescue Exception => e
    log_exception e
    flash[:error] = "Sorry, a system error has occured, please try again."
    render_create_response(flash, 422)
  end

  # DELETE /mines/1.js
  def destroy
    if ! params[:delete_these].blank?
      Mine.destroy(params[:delete_these])
      flash[:notice] = 'Mines destroyed'
      redirect_to :action => 'index'
    else
      @mine = Mine.destroy(params[:id])
      flash[:notice] = 'Mine destroyed'
      redirect_to :action => 'index'
    end
  end

  protected
  def render_create_response(flash_message, status)
    respond_to do |format|
      format.js { render :partial => 'mines/create.html.erb' }
      format.json do
        response.headers["Content-Type"] = "text/json; charset=utf-8"
        render :json => render_full_json_response(:flash => flash_message), :status => status
        flash.discard
      end
    end
  end
end
