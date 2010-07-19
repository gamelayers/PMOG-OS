class WatchdogsController < ApplicationController
  permit 'site_admin', :only => [:index, :search, :destroy]

  def index
    @watchdogs = Watchdog.paginate( :all,
      :order => 'created_at DESC',
      :page => params[:page],
      :per_page => 100 )

    render :action => 'list'
  end

  def search
    return unless site_admin?

    case params[:criteria]
    when "location"
      @watchdogs = Watchdog.paginate(:all, :include => [:user, :location], :conditions => ['watchdogs.location_id = locations.id and locations.url = ?', params[:q]], :page => params[:page], :per_page => 100, :order => "watchdogs.created_at DESC")
      @page_title = "Watchdogs on location -- #{params[:q]}"
      @h1content = "Watchdogs on #{params[:q]}"
    when "user"
      @searcheduser = User.find_by_login(params[:q])
      @watchdogs = Watchdog.paginate(:all, :include => [:user, :location], :conditions => ['watchdogs.user_id = ?', @searcheduser.id], :order => "watchdogs.created_at DESC", :page => params[:page], :per_page => 100)
      @page_title = "User #{params[:q]}'s watchdogs "
      @h1content = "#{params[:q]}'s Watchdogs"
    end
  end

  def destroy
    if ! params[:delete_these].blank?
      Watchdog.destroy(params[:delete_these])

      flash[:notice] = 'Watchdogs destroyed'
      redirect_to :action => 'index'
    elsif params[:id]
      begin
        @watchdog = Watchdog.find(params[:id])
        @watchdog.destroy

        flash[:notice] = 'Watchdog destroyed'
        redirect_to :action => 'index'
      rescue ActiveRecord::RecordNotFound => e
        flash[:error] = e.message
      end
    end
  end

  # PUT /users/location/watchdogs/attach.js
  def attach
    begin
      @watchdog = Watchdog.create_and_attach(current_user, params)

      flash[:notice] = 'Watchdog unleashed!'
      render_attach_response(flash)
    rescue PMOG::PMOGError => e
      flash[:error] = e.message
      render_attach_response(flash, 422)
    rescue ActiveRecord::RecordNotFound => e
      log_exception(e)
      flash[:error] = e.message
      render_attach_response(flash, 422)
    end
  end

  protected
  def render_attach_response(flash_message, status = 201)
    respond_to do |format|
      format.js { render :partial => 'watchdogs/attach.html.erb' }
      format.json do
        response.headers["Content-Type"] = "text/json; charset=utf-8"
        render :json => render_full_json_response(:flash => flash_message), :status => status
        flash.discard
      end
    end
  end
end
