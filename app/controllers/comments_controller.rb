#Controls the comments for acts_as_commentable implementations
#01/18/2008 marc@gamelayers.com
class CommentsController < ApplicationController
  before_filter :login_required, :except => [ :index, :show ]
  permit 'site_admin or steward', :only => :destroy

  # GET /comments
  def index
    # Maybe this can be an admin-only page for editing and deleting comments
    # but for now I'll just comment it out - duncan 05/02/09
    #@comments = Comment.find(:all)
    #
    #respond_to do |format|
    #  format.html # index.rhtml
    #  format.js   { render :json => @comments.to_json }
    #end
  end

  # GET /comments/1
  def show
    @comment = Comment.find(params[:id])

    respond_to do |format|
      format.html # show.rhtml
      format.js  { render :json => @tag.to_json }
    end
  end

  # GET /comments/new
  def new
    @comment = Comment.new
  end

  # POST /comments
  def create
    #params[:comment][:body] = params[:comment][:body].strip

    commentable = params[:commentable][:class].constantize.find(params[:commentable][:id])

    comment = Comment.new(:title => 'null', :comment => params[:comment][:body], :user_id => current_user.id)

    if comment.valid?
        commentable.add_comment(comment)
        current_user.reward_datapoints 2
        current_user.reward_pings Ping.value("Reply") if params[:commentable][:class] = 'Mission'

        Event.record :context => 'comment_created',
          :user_id => current_user.id,
          :message => ' just commented on the Mission <a href="' + commentable.pmog_host + send("#{commentable.class.to_s.downcase}_path", commentable.url_name) + '">' + commentable.name + '</a>'

        redirect_to send("#{commentable.class.to_s.downcase}_url", commentable.url_name)
        flash[:notice] = 'Comment added!'
    else
      redirect_to :controller => 'missions', :action => 'completed', :id => commentable.url_name
      flash[:notice] = 'Failed to add the comment'
    end
  end

  def check_length
    body_text = request.raw_post || request.query_string

    total_words = 0
    body_text.scan(/\b\S+\b/) { total_words += 1}
    total_chars = body_text.length
    if (total_chars >= 255)
      render :text => "<p class=\"error\">Warning: Length Exceeded! (You have #{total_chars} characters.)</p>"
    else
      render :nothing => true
    end
  end

  # POST /comments/1/destroy or i guess DELETE
  def destroy
    @comment = Comment.find(params[:id])
    if @comment.destroy
      # not taking the 2 points back... for now
      flash[:notice] = 'Comment destroyed.'
    else
      flash[:error] = 'Dohh! Comment not destroyed'
    end
    redirect_to send("#{@comment.commentable.class.to_s.downcase}_url", @comment.commentable.url_name)

  end
end
