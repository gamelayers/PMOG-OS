class InviteController < ApplicationController
  authorizes_through_yahoo

  before_filter :login_required

  def index
  	@page_title = "Invite Someone to "
    @supported_services = {:windows_live => "Windows Live", :gmail => "Gmail", :yahoo => "Yahoo!"}
  end

  # render a page explaining delegated authentication
  # bake the request params into the url the user clicks
  def start
    session[:invite_context] = params[:context]

    case params[:service].to_sym
      when :windows_live
        return_url = "http://thenethernet.com/invite/windows_live?authenticity_token=#{form_authenticity_token}"
        permissions = "Contacts.View" # we only need read access
        privacy_url = "http://thenethernet.com/about/privacy" # kinda surprised only MS asked for this
        @request_url = "https://consent.live.com/Delegation.aspx?RU=#{return_url}&ps=#{permissions}&pl=#{privacy_url}"
        @title = "Windows Live"
      when :gmail
        return_url = "http://thenethernet.com/invite/gmail"
        scope = "http://www.google.com/m8/feeds/contacts" # this is an obtuse request for just contacts
        secure = 1 # change this if you're testing
        session = 1 # we're doing a 1 time call
        @request_url = "https://www.google.com/accounts/AuthSubRequest?next=#{return_url}&scope=#{scope}&secure=#{secure}&session=#{session}"
        @title = "Gmail" #FIXME
      when :yahoo
        @request_url = authentication_url # thank god the yahoo auth plugin works pretty well
        @title = "Yahoo!"    
    end
    
    respond_to do |format|
      format.html
      format.js
    end
  end

  def add_friends
    session[:registered_emails] = nil
    session[:added_friends] = []
    params[:friend].each do |k, v|
      buddy = User.find_by_login(k)
      #buddy.add(current_user.id, 'acquaintance')
      session[:added_friends] << k
    end

    render :action => "select_friends.rjs"
  end 

  # either auto send emails, or draw the type-your-own 
  def parse_auto_invite
    session[:invite_context] = nil
    session[:registered_emails] = nil
    session[:unregistered_emails] = nil
    session[:invite_message] = params[:addNote]

    outgoing_addrs = []
    params[:emails].each do |k, v|
      outgoing_addrs << k
    end

    send_emails outgoing_addrs

    redirect_to :action => :sent_emails
  end

  def parse_direct_invite
    emails = []
    email_form_data = params[:emails]
    email_form_data.each do |k, v|
      emails << v unless v.empty?
    end
    session[:invite_message] = params[:addNote]

    send_emails emails

    redirect_to :action => :sent_direct_emails
  end

  def redirector
    if session[:invite_context].nil?
      flash[:error] = "We're sorry, The Nethernet has lost track of where you were."
      redirect_to '/'
      return
    end
    case session[:invite_context]
      when 'contacts'
        session[:invite_context] = :select
        redirect_to "/acquaintances/#{current_user.login}/#contactsFind"
        return
    end

    redirect_to '/'
    return
  end

  # <SERVICE SPECIFIC CALLS>
  def gmail
    if params[:token].nil?
      flash[:error] = "No authentication token returned."
      redirect_to ''
    end

    parse_emails User.match_gmail_api(params[:token])

    redirect_to :action => :redirector
  end

  def windows_live
    if params[:ConsentToken].nil?
      flash[:error] = "No authentication token returned."
      redirect_to ''
    end
 
    parse_emails User.match_windowslive(params[:ConsentToken])

    redirect_to :action => :redirector
  end

  def yahoo
    if params[:token].nil?
      flash[:error] = "No authentication token returned."
      redirect_to ''
    end

    creds = request_yahoo_credentials(params[:token])
    parse_emails User.match_yahoo(creds[:wssid], creds[:auth_cookie])

    redirect_to :action => :redirector
  end
  # </SERVICE SPECIFIC CALLS>

	def invite_forward
		session[:acquaintances_show_tab_state] = :contactsFind
		redirect_to :controller => :acquaintances, :action => :show, :id => current_user.login
	end

  private
  def parse_emails contacts

    registered = []
    unregistered = []

    contacts.each do |contact|
      player = Buddy.find_by_email(contact[:email])
      if player.nil?
        # spare anyone who has already been invited from a spamming
        invitee = BetaUser.find_by_email(contact[:email])
        unregistered << contact[:email].to_s if invitee.nil?
      else
        registered << contact[:email].to_s
      end
    end

    session[:registered_emails] = registered
    session[:unregistered_emails] = unregistered
  end

  def send_emails addrs
    session[:outgoing_emails] = []
    addrs.each do |email|
      begin
        BetaUser.email_invite(current_user, {:recipient => email, :message => session[:invite_message]})
      rescue MessageErrors::RecipientAlreadyPlaying
        session[:outgoing_emails] << email
      end

      session[:outgoing_emails] << email
    end
    session[:invite_message] = nil
  rescue Exception => e
    log_exception(e)
    # we still want to draw the congrats page, regardless of success
    # if we didn't, it'll draw the error instead because session[:outgoing_emails] == []
  end

end

