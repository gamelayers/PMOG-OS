# Lightpost are bookmarks that users create as they browse the web. They 
# use these bookmarks to help create missions later on. Note that we 
# have a route for lightposts nested in both locations *and* users.
class LightpostsController < ApplicationController
  before_filter :login_required
  before_filter :find_lightpost, :except => [:create, :index, :new, :sort]

  # GET /users/suttree/lightposts
  # GET /users/suttree/lightposts.js
  def index
    params[:column] = 'created_at'
    params[:order] = 'DESC'
    @user = User.find( :first, :conditions => { :login => params[:user_id] } )
    @page_title = @user.login + "'s Lightposts on "

    sort
  end
  
  def sort
    @user = User.find( :first, :conditions => { :login => params[:user_id] } )
    
    unless @user and @user.id == current_user.id
      flash[:notice] = 'Permission denied!'
      redirect_to '/' and return
    end
    
    (params[:order] && params[:order].downcase == 'asc') ? params[:order] = 'ASC' : params[:order] == 'DESC'
      
    if params[:column] 
      case params[:column].downcase
        when 'created_at'
          params[:column] = 'created_at'
        when 'description'
          params[:column] = 'description'
        else
          params[:column] = 'created_at'
      end
    else
      params[:column] = 'created_at'
    end
    
    pagination_params = { :per_page => 10, :page => params[:page] || 1, :order => "#{params[:column]} #{params[:order]}" }
    @lightposts = @user.lightposts.paginate(:all, pagination_params)
    
    respond_to do |format|
      format.html{ render :template => 'lightposts/index'}
    end
  end

  # GET /locations/:location_id/lightposts/new
  def new
    @location = Location.find(params[:location_id])
    @window_id = "new_lightpost_#{@location.id}"
    respond_to do |format|
      format.json { render :json => create_overlay('lightpost', :template => 'lightposts/new', :type => 'deploy') }
      format.js { render :json => create_overlay('lightpost', :template => 'lightposts/new', :type => 'deploy') }
    end
  end

  # POST /location/location_id/lightpost.js
  def create
    @lightpost = Lightpost.create_and_deposit(current_user,params)
    render_lightpost_response "Your lightpost is good to glow!"
  rescue PMOG::PMOGError => e
    render_lightpost_response e.message, :error, 422
  rescue Exception => e
    log_exception e
    render_lightpost_response "A system error has occured, please try again later.", :error, 422
  end

  def edit
    @page_title = 'Edit a Lightpost on '

    respond_to do |format|
      format.html #edit.html.erb
      format.js {
        render :update do |page| 
            @index = params[:lightpost_id].split('_').last
            page.replace_html params[:lightpost_id], :partial => 'ajax_edit'
        end
      }
    end
  end

  def replace_line
    respond_to do |format|
      format.js {
        render :update do |page| 
            @index = params[:lightpost_id].split('_').last
            page.replace_html params[:lightpost_id], :partial => 'lightpost', :locals => { :index => @index, :lightpost => @lightpost  }
        end
      }
    end
  end
  
  def update
    raise ArgumentError unless params[:lightpost] && params[:lightpost][:description]
    if @lightpost.update_attributes(:description => params[:lightpost][:description])
      
      if params[:lightpost] && params[:lightpost][:tag_list]
        Tagging.transaction do
          @lightpost.taggings.delete_all
          @lightpost.tag_list.add(params[:lightpost][:tag_list].split(','))
          @lightpost.save
          @lightpost.reload
        end
      end
      flash[:notice] = 'Changes Saved'
      respond_to do |format|
        format.html { redirect_to :action => :index, :user_id => current_user } #edit.html.erb
        format.js {
          render :update do |page| 
              @index = params[:lightpost_id].split('_').last
              page.replace_html params[:lightpost_id], :partial => 'ajax_edit'
          end
        }
      end
    else
      redirect_to :action => :edit, :user_id => current_user, :id => @lightpost.id
    end
  rescue ArgumentError
    flash[:error] = 'You are missing a required parameter.'
    redirect_to edit_user_lightpost_path(current_user, @lightpost)
  end

  def destroy
    if @lightpost.destroy
      flash[:notice] = 'You dismantled your lightpost.'
    else
      flash[:notice] = 'There was an error dismantling your lightpost.'
    end
    redirect_to :action => :index, :user_id => current_user
  end

  protected
  def find_lightpost
    @lightpost = current_user.lightposts.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:error] = 'Could not find lightpost'
    redirect_to('/')
  end

  def render_lightpost_response message, type = :notice, status = 201
    flash[type] = message
    respond_to do |format|
      format.html{ redirect_to user_lightposts_url(current_user) }
      format.json do
        response.headers["Content-Type"] = "text/json; charset=utf-8"
        render :json => render_full_json_response(:flash => flash), :status => status
        flash.discard
      end
    end
  end

end
