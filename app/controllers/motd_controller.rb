class MotdController < ApplicationController
  before_filter :login_required
  permit 'site_admin', :except => [ :dismiss, :index ]
  
  # GET /motd
  #   Lists the MOTDs and provides CRUD methods for site admins
  # GET /motd.json
  #   Returns the latest MOTD, if there is a new MOTD available. Uses the same conditional GET 
  #   hooks as the Message API. Should be polled infrequently by the extension.
  def index
    respond_to do |format|
      format.html {
        if site_admin?
          @page_title = "Message Of the Day on "
          @motds = Motd.paginate( :all,
                                  :order => "created_at DESC",
                                  :page => params[:page],
                                  :per_page => 100 )
        else
          flash[:notice] = "Permission denied"
          redirect_to '/' and return
        end
      }
      format.json { render_message_overlay }
    end
  end
  
  # POST /motd/id/dismiss.json
  # Dismiss this MOTD, so that the user doesn't see it again
  def dismiss
    @motd = Motd.find(params[:id])
    @window_id = params[:window_id].nil? ? @motd.id : params[:window_id]
    @motd.dismissals.dismiss current_user unless @motd.dismissals.dismissed_by? current_user
    
    respond_to do |format|
      format.json { render :json => { :content => 'MOTD Dismissed' }, :status => 422 }
    end
  end
  
  def create
    @motd = Motd.create(params[:motd])
    
    if @motd.valid?
      flash[:notice] = 'MOTD Created'
      Motd.expire_cache('latest')
      redirect_to :action => 'index'
    else
      flash[:notice] = 'Error creating MOTD'
      render :action => 'new'
    end
  end
  
  def edit
    @motd = Motd.find(params[:id])
  end
  
  def update
    @motd = Motd.find(params[:id])
    @motd.update_attributes(params[:motd])
    
    if @motd.valid?
      flash[:notice] = 'MOTD Updated'
      Motd.expire_cache('latest')
      redirect_to :action => 'index'
    else
      flash[:notice] = 'Error editing MOTD'
      render :action => 'edit'
    end
  end
  
  def destroy
    @motd = Motd.find(params[:id])
    @motd.destroy
    Motd.expire_cache('latest')
    
    flash[:notice] = 'MOTD destroyed'
    redirect_to :action => 'index'
  end
  
  private
  # Store some information about the end user, if supplied.
  # Deprected in favor of the browser stats on AMO
  def process_browser_stats
    return if params[:os].nil? or params[:browser_name].nil? or params[:browser_version].nil?
    
    args = { :user_id => current_user.id, :os => params[:os], :browser_name => params[:browser_name], :browser_version => params[:browser_version] }
    BrowserStat.create(args) unless BrowserStat.exists?(args)
  end

  # Renders either a 304 or the MOTD overlay
  def render_message_overlay
    @motd = Motd.caches(:latest)
    
    last_modified = @motd.created_at rescue 'Sun Feb 23 00:00:00 +0000 1975'.to_time
    
    render_not_modified_or(last_modified) do
      if @motd.dismissals.dismissed_by? current_user
        return # Only 304 the MOTD if it has been dismissed
      else
        render :json => create_overlay(@motd, { :type => 'message', :text => message_overlay({ :content => @motd.body, :from => 'PMOG' }).to_json })
      end
    end
  end
end
