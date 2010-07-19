class ForumsController < ApplicationController
  session :off, :if => Proc.new { |request| request.parameters[:format] == 'rss' || request.parameters[:format] == 'xml' }
  
  before_filter :login_required, :only => [:stewards, :toggle_inactive]
  permit 'site_admin or steward', :only => [:stewards, :toggle_inactive]

  # GET /forums
  def index
    @page_title = 'Forums on '
    if logged_in? and current_user.admin_or_steward?
      @forums = Forum.find(:all, :order => 'position ASC')
    else
      @forums = Forum.cached_find_all
    end

    respond_to do |format|
      format.html # index.rhtml
    end
  end

  # GET /forums/1
  def show
    @forum = Forum.cached_find_by_url_name(params[:id])
    
    redirect_to :action => 'index' and return unless @forum.public? or (logged_in? and current_user.admin_or_steward?)
    
    # The topics are sorted in forum.rb at the association definition.
    @topics = @forum.topics.paginate(:page => params[:page])
    
    @page_title = @forum.title + ', part of the Forums on '
    
    respond_to do |format|
      format.html # show.rhtml
      format.rss  { render :action => 'show.xml.builder', :layout => false }
    end
  end

  # GET /forums/new
  def new
    # Get them all so we can properly assign a position
    forums = Forum.find(:all)
    
    @forum = Forum.new
    @page_title = 'Creating A New Forum on '
    
    #if we have less than one book, let's just set this position value to 1
    unless forums.nil?
      if forums.size < 1
        @forum.position = 1
      else
        #if we have more than one forum, let's get the position of the last forum
        #and set this new forums's position (in the form field at least), to 
        #1+ that value
        @forum.position = forums.last.position + 1
      end
    end
  end

  # GET /forums/1;edit
  def edit
    @forum = Forum.cached_find_by_url_name(params[:id])
    @page_title = 'Editing ' + @forum.title + ' Forum on '
    check_auth
  end

  # POST /forums
  def create
    @forum = Forum.new(params[:forum])
    
    @forum.pmog_only = params[:forum][:pmog_only]
    @forum.public = params[:forum][:private] == "0" ? 1 : 0
    
    @page_title = 'Create a New Forum on '

    respond_to do |format|
      if @forum.save
        
        forums = Forum.find(:all)
        
        if @forum.position > forums.last.position + 2

                #if the books position is greater than my last book in my list
                #change it to fit right after the last one, for example
                #if my last item has a position of 6, let's set this new one to 
                #a position of 7
                @forum.position = forums.last.position + 1
        end
        [ 'forums', "forum_#{@forum.url_name}" ].each{ |key| Forum.expire_cache(key) }
        flash[:notice] = 'Forum was successfully created.'
        format.html { redirect_to forum_url(@forum) }
      else
        format.html { render :action => 'new' }
      end
    end
  end

  # PUT /forums/1
  def update
    @forum = Forum.cached_find_by_url_name(params[:id])
    check_auth
    
    # Fuck, this public/private stuff is crappy - duncan 24/12/08
    @forum.pmog_only = params[:forum][:pmog_only]
    @forum.public = params[:forum][:private] == "0" ? 1 : 0
    
    respond_to do |format|
      if @forum.update_attributes(params[:forum])
        [ 'forums', "forum_#{@forum.url_name}" ].each{ |key| Forum.expire_cache(key) }
        flash[:notice] = 'Forum was successfully updated.'
        format.html { redirect_to forum_url(@forum) }
      else
        format.html { render :action => 'edit' }
      end
    end
  end

  # DELETE /forums/1
  def destroy
    @forum = Forum.cached_find_by_url_name(params[:id])
    check_auth
    @forum.destroy

    respond_to do |format|
      format.html { redirect_to forums_url }
    end
  end
  
  def move
   
    if ['move_lower', 'move_higher', 'move_to_top', 'move_to_bottom'].include?(params[:move])
     #if the incoming params contain any of these methods and a numeric forum_id, 
     #let's find the forum with that id and send it the acts_as_list specific method
     #that rode in with the params from whatever link was clicked on
      @forum = Forum.find_by_url_name(params[:id])
      @forum.send(params[:move])
    end
    
    [ 'forums', "forum_#{@forum.url_name}" ].each{ |key| Forum.expire_cache(key) }
            
    #after we're done updating the position (which gets done in the background
    #thanks to acts_as_list, let's just go back to the list page, 
    #refreshing the page basically because I didn't say this was an RJS
    #tutorial, maybe next time
    redirect_to :action => :index
  end

  def toggle_inactive
    Forum.find_by_url_name(params[:id]).toggle_inactive
    redirect_to :action => :index
  end
  
  def stewards
  	@page_title = "Stewards of "
    @stewards = User.find_all_by_role 'steward'
		@soul_marks = SoulMark.find(:all, :order => 'created_at desc', :limit => 25)
    @stewardings = Stewarding.find(:all, :order => 'created_at desc').paginate(:page => params[:page])
    @privateposts = Post.find( :all, 
      :conditions => 'forums.public = 0',
      :order => "posts.created_at DESC", 
      :include => { :topic => :forum }, :limit => 20 )
    @players_to_welcome = User.find(:all, :conditions => "total_datapoints >= #{GameSetting.value("Shoat Welcome DP Threshold").to_i} AND welcomed IS NULL", :order => 'created_at DESC', :limit => 32)
  end
  
  def search
    @page_title = "#{params[:q]} - Searching Forums on "
    if params[:q]
      @posts = Post.search(params[:q], :include => [:topic], :limit => 25, :order => 'posts.created_at DESC')
      @posts = @posts.reject{ |p| p.topic.forum.pmog_only == true || p.topic.forum.public == false } # Hack to exlude private forums from search - duncan 15/12/08
    end
  end
  
  protected
  def check_auth
    unless site_admin?
      flash[:notice] = 'Access denied'
      redirect_to forums_url and return
    end
  end
end
