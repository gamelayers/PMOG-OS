class TopicsController < ApplicationController
  session :off, :if => Proc.new { |req| req.params[:format] == "rss" || req.params[:format] == "xml" }
  permit 'site_admin', :only => [ :hide ]
  permit 'site_admin or steward', :only => [ :pin, :unpin, :lock, :unlock, :move ]

  # GET /topics
  def index
    render :nothing => true and return # not implemented

    @topics = Topic.cached_find_all
    @page_title = "Topics in the Forums on "

    respond_to do |format|
      format.html # index.rhtml
    end
  end

  # GET /topics/1
  def show
    if params[:id] == 'the-other-day-online' && current_user.login == 'burdenday'
      flash[:notice] = "Not for your eyes, Joe. Ask Duncan for more info :)"
      redirect_to '/' and return
    end

    @forum = Forum.find_by_url_name(params[:forum_id])
    @topic = Topic.cached_find_by_url_name(params[:id])

    check_auth('stewardstoo') if @forum.private?

    #@posts = Post.paginate_all_by_topic_id @topic.id, :page => params[:page]
    #@posts = @topic.posts.paginate(:page => params[:page]) rescue []
    if site_admin? or steward?
      @posts = Post.paginate_with_inactive(:all, :conditions => { :topic_id => @topic.id }, :order => "created_at ASC", :page => params[:page])
    else
      @posts = @topic.posts.paginate(:page => params[:page]) rescue []
    end
    @page = params[:page] if params[:page].to_i > 1 # hack for permalinks

    if @topic.nil?
      @page_title = 'Unknown Topic'
    else
      @page_title = @topic.title + ' in the Forums on '
    end

    respond_to do |format|
      format.html # show.rhtml
      format.rss  { render :action => 'show.xml.builder', :layout => false }
    end
  end

  # GET /topics/new
  def new
    @topic = Topic.new
    @post = Post.new
    @page_title = "A New Topic in the Forums on "
  end

  # GET /topics/1;edit
  def edit
    @topic = Topic.cached_find_by_url_name(params[:id])
    check_auth
    @page_title = "Editing " + @topic.title + " in the Forums on "
  end

  # POST /topics
  def create
    # @topic = current_user.topics.create(params[:topic])
    # @post = current_user.posts.create( :body => params[:topic][:description], :topic_id => @topic.id )
    @forum = Forum.find_by_url_name(params[:forum_id])
    check_auth('stewardstoo') if @forum.private?

    @topic = @forum.topics.create(:title => params[:topic][:title],
                                  :description => params[:topic][:description],
                                  :user_id => current_user.id)

    unless @topic.valid?
      render :action => 'new'
      return
    end

    @forum.reload
    @forum.save!

    @post = @topic.posts.create(:body => params[:topic][:description],
                                :user_id => current_user.id)
    @topic.reload
    @topic.save!

    current_user.reward_pings Ping.value("New Post")

    respond_to do |format|
        [ "topics", "topic_#{@topic.url_name}" ].each{ |key| Topic.expire_cache(key) }
        [ "forums", "forum_#{@forum.url_name}" ].each{ |key| Forum.expire_cache(key) }
        flash[:notice] = 'You created a New Topic! +' + Ping.value("New Post").to_s + '<img src="/images/shared/elements/ping-16.png" width="16" height="16" border="0" alt="pings" class="menu_img_no_border">'
        unless @topic.forum.private?
          Event.record :context => 'forum_topic_created',
            :user_id => current_user.id,
            :message => "just created a new forum topic: <a href=\"#{forum_topic_url(@topic)}\">#{simple_sanitize(@topic.title)}</a>."
        end
        format.html { redirect_to forum_topic_url(@topic) }
    end
    rescue ActiveRecord::RecordInvalid
      respond_to do |format|
        format.html { render :action => 'new'}
      end
  end

  # PUT /topics/1
  def update
    @topic = Topic.cached_find_by_url_name(params[:id])
    check_auth

    respond_to do |format|
      if @topic.update_attributes(params[:topic])
        [ "topics", "topic_#{@topic.url_name}" ].each{ |key| Topic.expire_cache(key) }
        flash[:notice] = 'Topic was successfully updated.'
        format.html { redirect_to forum_topic_url(@topic) }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  # DELETE /topics/1
  def destroy
    @topic = Topic.cached_find_by_url_name(params[:id])
    @forum = @topic.forum
    check_auth

    @topic.posts.each do |post|
      post.destroy
    end

    @topic.destroy

    respond_to do |format|
      [ "forums", "forum_#{@forum.url_name}" ].each{ |key| Forum.expire_cache(key) }
      format.html { redirect_to forums_path }
    end
  end

  def move
    new_forum = Forum.find(params[:topic][:topic_forum_id])
    topic = Topic.find(params[:topic][:id])

    if topic.forum.id != new_forum.id
      topic.forum = new_forum
      topic.save
    end

    redirect_to '/forums'
  end

  def pin
    @topic = Topic.find( :first, :conditions => { :url_name => params[:id] } )
    #ActiveRecord::Base.connection.execute("UPDATE topics SET pinned=1 WHERE id='#{@topic.id}'")
    @topic.pinned = true
    @topic.save
    Stewarding.create(:user => current_user, :action => 'pin', :stewardable => @topic)
    Topic.expire_cache( 'topic_' + @topic.url_name.to_s )
    flash[:notice] = "#{@topic.title} pinned."
    redirect_to forum_topic_path(@topic)
  rescue ActiveRecord::StatementInvalid
    flash[:error] = 'Pin unsuccessful...?!'
    redirect_to forum_topic_path(@topic)
  end

  def unpin
    @topic = Topic.find( :first, :conditions => { :url_name => params[:id] } )
    #ActiveRecord::Base.connection.execute("UPDATE topics SET pinned=0 WHERE id='#{@topic.id}'")
    @topic.pinned = false
    @topic.save
    Stewarding.create(:user => current_user, :action => 'unpin', :stewardable => @topic)
    Topic.expire_cache( 'topic_' + @topic.url_name.to_s )
    flash[:notice] = "#{@topic.title} unpinned."
    redirect_to forum_topic_path(@topic)
  rescue ActiveRecord::StatementInvalid
    flash[:error] = 'Unpin unsuccessful... ?!'
    redirect_to forum_topic_path(@topic)
  end

  def lock
    @topic = Topic.find( :first, :conditions => { :url_name => params[:id] } )
    ActiveRecord::Base.connection.execute("UPDATE topics SET locked=1 WHERE id='#{@topic.id}'")
    Stewarding.create(:user => current_user, :action => 'lock', :stewardable => @topic)
    Topic.expire_cache( 'topic_' + @topic.url_name.to_s )
    flash[:notice] = "#{@topic.title} locked."
    redirect_to forum_topic_path(@topic)
  rescue ActiveRecord::StatementInvalid
    flash[:error] = 'Lock unsuccessful... ?!'
    redirect_to forum_topic_path(@topic)
  end

  def unlock
    @topic = Topic.find( :first, :conditions => { :url_name => params[:id] } )
    ActiveRecord::Base.connection.execute("UPDATE topics SET locked=0 WHERE id='#{@topic.id}'")
    Stewarding.create(:user => current_user, :action => 'unlock', :stewardable => @topic)
    Topic.expire_cache( 'topic_' + @topic.url_name.to_s )
    flash[:notice] = "#{@topic.title} unlocked."
    redirect_to forum_topic_path(@topic)
  rescue ActiveRecord::StatementInvalid
    flash[:error] = 'Ulock unsuccessful... ?!'
    redirect_to forum_topic_path(@topic)
  end

  # Add the ability to hide forum posts and threads as opposed to deleting them permanently
  def hide
    @topic = Topic.find( :first, :conditions => { :url_name => params[:id] } )

    # We should deactivate each post assigned to a topic as well.
    @topic.posts.each do |p|
      p.deactivate!
      p.save
    end

    # Then deactivate the topic itself.
    @topic.deactivate!
    @topic.save

    Topic.expire_cache( 'topic_' + @topic.url_name.to_s )

    # Go back to the forum root.
    redirect_to forums_path
  end

  # Subscribe to email notifications of topic changes.
  def subscribe
    @forum = Forum.find_by_url_name(params[:forum_id])
    @topic = Topic.find_by_url_name(params[:id])
    check_auth('stewardstoo') if @forum.private?

    Topic.add_subscription(@topic, current_user)
    respond_to do |format|
      flash[:notice] = "You have subscribed to #{@topic.title}"
      format.html { redirect_to forum_topic_path(@topic) }
      format.js
    end
  end

  # Unsubscribe to email notification of topic changes
  def unsubscribe
    @topic = Topic.find_by_url_name(params[:id])
    Topic.remove_subscription(@topic, current_user)
    respond_to do |format|
      flash[:notice] = "You have unsubscribed from #{@topic.title}"
      format.html { redirect_to forum_topic_path(@topic) }
      format.js
    end
  end

  protected
  def check_auth(stewardstoo = false)
    unless site_admin? or (stewardstoo != false and current_user.has_role?('steward')) or current_user == @topic.user
      flash[:notice] = "Access denied"
      redirect_to forums_url and return
    end
  end
end
