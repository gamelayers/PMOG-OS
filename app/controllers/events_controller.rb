# Renders a list of events that should be displayed in the browser
class EventsController < ApplicationController
  before_filter :login_required, :only => :ticker

  def index
    @page_title = 'Events on '

    if logged_in?
      # @contacts_events = @user.events.cached_news_feed_for(10)
      # @allies_events = @user.events.cached_news_feed_for('ally', 10)
      # @rivals_events = @user.events.cached_news_feed_for('rival', 10)
    end

    if params[:time]
      time = params[:time].to_i
      # We only want the special time window to be between 1 and 60 minutes
      time = 1  if time <= 0
      time = 60 if time > 60
      @events = Event.by_timeframe(time).paginate(:page => params[:page], :per_page => 100)
    elsif params[:user_id]
      @user = User.find_by_login(params[:user_id])
      @page_title = @user.login + "'s events on "
      @events = @user.events.cached_your_news_feed(500).paginate(:page => params[:page], :per_page => 100)
    else
      @events = Event.list(500).paginate(:page => params[:page], :per_page => 100)
    end

    respond_to do |format|
      format.html # index.rhtml
      format.rss {
        render :action => 'rss.xml.builder', :layout => false
      }
      format.xml {
        render :xml, @events.to_xml(:include => [:user])
      }
    end
  end

  # Your latest news feed
  def ticker
    if params[:user_id]
      login = params[:user_id]
      ticker_method = 'cached_your_news_feed'
    elsif params[:acquaintance_id]
      login = params[:acquaintance_id]
      ticker_method = 'cached_acquaintances_news_feed'
    end

    @user = User.find( :first, :conditions => { :login => login } )
    @events = @user.events.send(ticker_method, 100)
    @page_title = @user.login + '\'s events on '
  end

  def contacts
    @user = User.find_by_login(params[:user_id])
    if params[:limit]
      limit = params[:limit]
    else
      limit = 10
    end

    @events = Event.recent_for(@user.buddies.cached_contacts_ids, limit)

    respond_to do |format|
      format.html # index.rhtml
      format.rss {
        render :action => 'rss.xml.builder', :layout => false
      }
      format.xml {
        render :xml, @events.to_xml(:include => [:user])
      }
    end

  end

  def triggered
    @user = User.find_by_login(params[:user_id])

    if params[:limit]
      limit = params[:limit]
    else
      limit = 10
    end

    # Trying this uncached so I can see if the data is wrong or the cache isn't refreshing.
    @events = @user.events.your_triggered_feed(limit)

    respond_to do |format|
      format.html # index.rhtml
      format.rss {
        render :action => 'rss.xml.builder', :layout => false
      }
      format.xml {
        render :xml, @events.to_xml(:include => [:user])
      }
    end

  end

  def combined
    @user = User.find_by_login(params[:user_id])

    if params[:limit]
      limit = params[:limit]
    else
      limit = 10
    end

    # This is too intensive so we're going to return the same as the triggered for now.
    #@events = @user.events.your_combined_feed(limit)

    @events = @user.events.your_triggered_feed(limit)

    respond_to do |format|
      format.html # index.rhtml
      format.rss {
        render :action => 'rss.xml.builder', :layout => false
      }
      format.xml {
        render :xml, @events.to_xml(:include => [:user])
      }
    end

  end

  def mark_all_read
    current_user.system_events.mark_unread_read

    flash[:notice] = "Marked all unread system events as read."

    respond_to do |format|
      format.html {
        redirect_to system_user_messages_path(current_user)
      }
      format.json {
        response.headers["Content-Type"] = "text/json; charset=utf-8"
        render :json => render_full_json_response(:flash => flash), :status => 200
        flash.discard
      }
    end
  end

end
