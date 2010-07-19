class MessagesController < ApplicationController
  include ActsAsTinyURL

  before_filter :buggy_version, :only => :index
  before_filter :login_required
  before_filter :security_check, :only => [ :index, :sent, :new, :destroy ]

  # GET /users/login/messages
  # GET /users/login/messages.js
  #
  # Note that for .html views, we display all +messages+ and paginate them. For .js though.
  # the browser polls this url periodically, and we only render one +message+ at a time
  # We also use conditional GET to cut down on bandwidth by rendering a 304 if there
  # are no new messages for the user. Note that we also ignore params[:user_id] and
  # use +current_user+ instead
  def index
    respond_to do |format|
      format.html {
        @page_title = current_user.login + '\'s Messages on '
        @messages = current_user.messages.page(params[:page])
        current_user.messages.mark_these_as_read(@messages)
      }
      format.rss {
        @messages = current_user.messages.page(params[:page])
        last_modified = @messages.first.created_at rescue 'Sun Feb 23 00:00:00 +0000 1975'.to_time
        render_not_modified_or(last_modified) do
          current_user.messages.mark_these_as_read(@messages)
          render :action => 'rss.xml.builder', :layout => false
        end
      }
      format.json {
        return if buggy_version
        record_activity
        render_message_overlay
      }
      format.js {
        return if buggy_version
        record_activity
        render_message_overlay
      }
    end
  end

  def system
    respond_to do |format|
      format.html {
        @page_title = current_user.login + '\'s Game Notices on '
        @events = current_user.system_events.paginate(:page => params[:page], :per_page => 10)
        render :action => :events
      }
    end
  end

  # GET /users/login/messages/sent
  def sent
    @page_title = current_user.login + '\'s Sent Messages on '
    @messages = current_user.sent_messages.page(params[:page])

    respond_to do |format|
      format.html { render :action => :index }
    end
  end

  # GET /users/login/messages/new.js
  def new
    # @window_id = create_uuid
    # @recipient = params[:recipient] || ''
    # respond_to do |format|
    #   format.json { render :json => create_overlay('messages', :template => 'messages/new') }
    #   format.js { render :json => create_overlay('messages', :template => 'messages/new') }
    # end
  end

  # POST /users/login/messages
  # POST /users/login/messages.js
  def create
    @messages, @recipients = Message.create_and_deposit(current_user, params)
    respond_to do |format|
      flash[:notice] = "Message sent! +" + Ping.value("Reply").to_s + ' pings'
      format.html { redirect_to user_messages_path(current_user) }
      format.json do
        response.headers["Content-Type"] = "text/json; charset=utf-8"
        #render :json => render_full_json_response(:flash => flash), :status => 201
        render :json => {:flash => flash}.to_json, :status => 201
        flash.discard
      end
      format.js
    end
  rescue ActiveRecord::RecordNotFound => e
    handle_create_error(e.message)
  rescue Message::EmptyBodyError => e
    handle_create_error(e.message)
  rescue Message::EmptyRecipientError => e
    handle_create_error(e.message)
  rescue Message::InsufficientDpError => e
    handle_create_error(e.message)
  rescue Message::TooManyRecipientsError => e
    handle_create_error(e.message)
  end

  # POST /users/login/messages/message_id/reply.js
  def reply
    @message = Message.find(params[:id])
    @window_id = params[:window_id].nil? ? @message.id : params[:window_id]

    respond_to do |format|
      format.js { render :json => create_overlay('messages', :template => 'messages/reply') }
      format.json { render :json => create_overlay('messages', :template => 'messages/reply') }
    end
  end

  def read
    @message = Message.find(params[:id])
    if @message.recipient == current_user
      @message.mark_as_read
    end

    if @message.save
      flash[:notice] = "Message marked as read."
      respond_to do |format|
        format.json {
          render :json => render_full_json_response(:flash => flash), :status => 200
          flash.discard
        }
      end
    end
  end

  # DELETE /users/login/messages/message_id
  def destroy
    render :nothing => true and return unless params[:user_id] == current_user.login

    Message.find(params[:id]).destroy
    render :inline => 'ok'
  end

  def invite
    BetaUser.email_invite(current_user, params)
    flash[:notice] = INVITE_RESPONSE[rand(INVITE_RESPONSE.length)]

    respond_to do |format|
      format.json do
        render :json => render_full_json_response(:flash => flash), :status => 201
        flash.discard
      end
    end

  rescue Exception => e
    flash[:error] = "Exception: " + e
    respond_to do |format|
      format.json do
        render :json => render_full_json_response(:flash => flash), :status => 404
        flash.discard
      end
    end
  rescue Message::RecipientAlreadyPlaying => e
    flash[:error] = "O HAI.Look at that. Your friend is already a player on The Nethernet! Add them as a friend?"

    respond_to do |format|
      format.json do
        render :json => render_full_json_response(:flash => flash, :friend => User.find_by_email(params[:recipient]).login), :status => 422
        flash.discard
      end
    end
  end

  # POST /users/login/messages/summon?summoned=some_login&location_id=somelocation_uuid
  def summon
    @messages, @recipients, @location =  Message.summon_player_for(current_user, params)
    flash[:notice] = "Success, you summoned #{@recipients.map{|x|x.login}.join(', ')} to #{@location.url}."

    respond_to do |format|
      format.json do
        render :json => render_full_json_response(:flash => flash), :status => 201
        flash.discard
      end
    end

  rescue ActiveRecord::RecordNotFound => e
    handle_create_error("The player could not be summoned because we could not find the page you are on.")
  rescue Message::EmptyRecipientError => e
    handle_create_error(e.message)
  end

  # POST /users/login/messages/summon/some_id
  def summoned
    @summon = current_user.messages.find(params[:id])

    Message.send_summons_acceptance_from(current_user, @summon)
    Message.send_summon_receipt(current_user, @summon)

    flash[:notice] = "Summons confirmation sent"
    respond_to do |format|
      format.json do
        render :json => render_full_json_response(:flash => flash), :status => 201
        flash.discard
      end
    end
  rescue ActiveRecord::RecordNotFound

    # No one to notify of this error so skip it.
    render :nothing => true, :status => 422
  end

  protected

  # Just to be sure we're only viewing our own messages
  def security_check
    redirect_to "/users/#{current_user.login}/messages" unless params[:user_id] == current_user.login
  end

  # Older versions of the extension hammer the site due to a bug. Ignore them now.
  # - version 0.403 was out of control and spammed the message API mercilessly
  # - version 0.6.0 had a malformed request string, resulting in no 304s
  # - version 0.6.2 spammed us mercilessly at 5 times per second
  def buggy_version
    if params[:format] == 'json' && (params[:version].nil? or params[:version].to_f < 0.403 or params[:version].size == 56 or params[:version] == '0.6.2')
      render :nothing => true, :status => 304
      return true
    else
      return false
    end
  end

  def record_activity
    UserActivity::update(current_user, params[:version])
    record_hourly_activity
    record_daily_activity
  end

  # Hourly activity stats. Records a level of passive activity.
  # Note that we use Time.now.to_date rather than Date.today as our timezone code
  # intercept that, and we want to measure a strict metric of how many people we're
  # pinging our messaging api concurrent, at this time *on the server*.
  def record_hourly_activity
    unless cookies[:hourly_active_user].to_s == Date.today.to_s + '-' + Time.now.hour.to_s || session[:hourly_active_user].to_s == Date.today.to_s + '-' + Time.now.hour.to_s
      session[:hourly_active_user] = Date.today.to_s + '-' + Time.now.hour.to_s
      cookies[:hourly_active_user] = { :value => Date.today.to_s + '-' + Time.now.hour.to_s, :expires => Date.today.at_midnight }
      HourlyActivity.record(current_user, params[:version], Date.today, Time.now.hour)
    end
  end

  # Daily activity stats. Records a level of passive activity.
  def record_daily_activity
    unless cookies[:daily_active_user].to_s == Date.today.to_s || session[:daily_active_user].to_s == Date.today.to_s
      session[:daily_active_user] = Date.today.to_s
      cookies[:daily_active_user] = { :value => Date.today.to_s, :expires => Date.today.at_midnight }
      DailyActivity.record(current_user, params[:version], Date.today.to_s)
    end
  end

  # Send an overlay to the extension, using conditional GET
  def render_message_overlay
    # Disabled as this is quite slow, especially when a new version is deployed
    #if new_version_available
    #  title = "Version #{PMOG_EXTENSION_VERSION} Now Available!"
    #  body  = "There's a new Nethernet extension! <br /><a href=\"#{host}/guide/support/toolbar\">Update The Nethernet</a> or <a href=\"#{host}/about/versions\">Read More</a>"
    #
    #  # If the user has already received an upgrade message, just tack another
    #  # upgrade message onto the bottom of subsequent PMails.
    #  if current_user.messages.find_by_title(title)
    #    @message = current_user.messages.latest
    #    @message.body = @message.body + '<br /><hr />' + body
    #  else
    #    # Mark all messages as read so that the next message they receive is the important one
    #    current_user.messages.mark_all_as_read
    #    send_pmog_message :recipient => current_user, :title => title, :body => body
    #    @message = current_user.messages.find_by_title(title) # Make sure we get the right message
    #  end
    #else
    #  @message = current_user.messages.latest
    #end

    # Just get the latest message and append an upgrade notice if required
    body  = "There's a new Nethernet extension! <br /><a href=\"#{host}/guide/support/toolbar\">Update The Nethernet</a> or <a href=\"#{host}/about/versions\">Read More</a>"
    @message = current_user.messages.latest
    @message.body = @message.body + '<br /><hr />' + body if new_version_available

    last_modified = @message.created_at rescue 'Sun Feb 23 00:00:00 +0000 1975'.to_time
    render_not_modified_or(last_modified) do
      if @message.nil? or @message.read?
        return # render_not_modified_or will render a 304 for us
      else
        @message.mark_as_read if params[:version].to_f < 0.6 # Extensions >= 0.6 mark messages as read when you dismiss them
        render :json => create_overlay('messages', { :type => 'message', :text => message_overlay(@message.for_overlay) })
      end
    end
  end

  private
  # Stolen from application helper, sorry about that.
  def host
    if request.env[ 'HTTP_HOST' ] == 'ext.pmog.com' || request.env[ 'HTTP_HOST' ] == 'ext.thenethernet.com'
      return 'http://thenethernet.com'
    else
      return 'http://' + request.env[ 'HTTP_HOST' ] rescue 'http://localhost:3000'
    end
  end

  def handle_create_error(msg = 'Error Creating Message.',options = {})
    flash[:error] = msg
    respond_to do |format|
      format.html { redirect_to(user_messages_path(current_user)) }
      format.json do
        # This line was causing this error:
        # SyntaxError Exception: compile error
        # messages_controller.rb:170: unterminated string meets end of file
        # response.headers["Content-Type"] = "text/json; charset=utf-8"
        render :json => render_full_json_response(options.merge(:flash => flash)), :status => 422
        flash.discard
      end
      format.js
    end
  end
end
