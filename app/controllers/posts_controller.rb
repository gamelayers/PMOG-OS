class PostsController < ApplicationController
  session :off, :if => Proc.new { |req| req.params[:format] == "rss" || req.params[:format] == "xml" rescue nil }

  def latest
    @page_title = "The Latest Posts on "
    @posts = Post.caches(:latest, :with => current_user, :ttl => 1.hour)
    @forums = Forum.cached_find_all
    respond_to do |format|
      format.html # latest.rhtml
      format.rss  { render :action => "latest.xml.builder", :layout => false }
    end
  end

  # Safe RSS feed for news.pmog.com
  def latest_for_weblog
    respond_to do |format|
      format.rss  {
        @posts = Post.caches(:latest_for_weblog, :ttl => 4.hours)
        render :action => "latest.xml.builder", :layout => false
      }
    end
  end

  # GET /posts
  def index
    render :nothing => true and return # not implemented

    @posts = Post.cached_find_all

    respond_to do |format|
      format.html # index.rhtml
    end
  end

  # GET /posts/1
  def show
    @post = Post.cached_find_by_id(params[:id])
    redirect_to '/forums' and return if @post.topic.forum.private?

    respond_to do |format|
      format.html # show.rhtml
    end
  end

  # GET /posts/new
  def new
    @post = Post.new
  end

  # GET /posts/1;edit
  def edit
    @post = Post.find_by_id(params[:id])
    @page_title = "Editing a Post in the Forums on "
    check_auth
  end

  # POST /posts
  def create
    # I think using the association proxy method to build the posts is where it might be getting hosed up and moved
    # to different topics. I'm going to create it explicitly and I believe that will work. I can't recreate it so
    # it's all really a crap shoot.
    #@post = current_user.posts.create(params[:post])
    @topic = Topic.find_by_url_name(params[:topic_id])
    @post = Post.new(:body => params[:post][:body], :topic_id => @topic.id, :user_id => current_user.id)

    #@post.topic.updated_at = Time.now.to_s(:db)
    # We have to reload the topic before we save it
    # or the counter_cache fails.
    #@post.topic.reload
    #@post.topic.save

    respond_to do |format|
      if @post.save
        # Clear cache
        [ "posts", "post_#{@post.id}", "post_recent_total" ].each{ |key| Post.expire_cache(key) }
        [ "topics", "topic_#{@topic.url_name}" ].each{ |key| Topic.expire_cache(key) }

        current_user.reward_pings Ping.value("Reply").to_i
        flash[:notice] = 'You created a New Post! +' + Ping.value("Reply").to_s + '<img src="/images/shared/elements/ping-16.png" width="16" height="16" border="0" alt="pings" class="menu_img_no_border">'
        unless @topic.forum.private?
          event_data = {:context => 'forum_post_created',
            :user_id => current_user.id,
            :message => "posted in <a href=\"#{forum_topic_url(@post.topic)}\">#{simple_sanitize(@post.topic.title)}</a> in the Forums"}

          # show a notice, but don't spam people when they reply to people replying to their thread
          event_data.merge!(:recipient_id => @topic.user.id) unless @topic.user.id == current_user.id

          Event.record event_data
        end
        format.html { redirect_to forum_topic_path(:forum_id => @topic.forum, :id => @topic, :page => "#{@topic.posts.paginate(:page => nil).total_pages}", :anchor => @post.id) }
      else
        format.html { render :action => "new" }
      end
    end
  end

  # PUT /posts/1
  def update
    @post = Post.find_by_id(params[:id])
    check_auth

    @post.topic.updated_at = Time.now.to_s(:db)
    @post.topic.save

    respond_to do |format|
      if @post.update_attributes(params[:post])
        # Clear cache
        [ "posts", "post_#{@post.id}" ].each{ |key| Post.expire_cache(key) }
        [ "topics", "topic_#{@post.topic.url_name}" ].each{ |key| Topic.expire_cache(key) }

        flash[:notice] = 'Post was successfully updated.'
        format.html { redirect_to forum_topic_url(@post.topic) }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  # DELETE /posts/1
  def destroy
    @post = Post.cached_find_by_id(params[:id])
    @topic = @post.topic
    check_auth
    @post.destroy

    if @topic.posts.count == 0
      @topic.destroy
      redirect_to forums_path
      return
    end

    respond_to do |format|
        format.html { redirect_to forum_topic_path(@post.topic) }
    end
  end

  # Enable hiding of individual posts
  def hide
    @post = Post.cached_find_by_id(params[:id])

    @post.deactivate!
    @post.save

    redirect_to forum_topic_path(@post.topic)
  end

  protected
  def check_auth
    unless site_admin? or current_user == @post.user
      flash[:notice] = "Access denied"
      redirect_to forums_url and return
    end
  end
end
