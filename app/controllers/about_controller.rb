class AboutController < ApplicationController
  # For the Engine Yard monitoring, add to this as required
  session :off, :only => :ey_test
  skip_before_filter :login_from_cookie, :only => :ey_test
  skip_before_filter :login_from_browser, :only => :ey_test
  skip_before_filter :last_seen, :only => :ey_test
  skip_before_filter :set_host, :only => :ey_test
  skip_before_filter :local_cache_for_request, :only => :ey_test
  skip_filter :set_timezone, :only => :ey_test
  skip_filter :catch_errors, :only => :ey_test

  # This action exists to be monitored by Engine Yard.
  # Note that this works in conjunction with the logger method below.
  # See http://forum.engineyard.com/forums/6/topics/21
  def ey_test
    render :text => 'Hello World'
  end

  # Disabling logging for the whole controller. This is an attempt to reduce
  # memory leaks, as EngineYard hit /ey_test regularly and that may be
  # the source of some problems.
  # See http://www.ruby-forum.com/topic/95146
  def logger
  end

  def index
  	@page_title = 'About '
  end
  
  def credits
    @page_title = 'Credits for '
  end
  
  def sightseeing
    @page_title = 'A Preview of '
  end

  def privacy
    @page_title = 'The Privacy Policy of '
  end

  def contact
    @page_title = 'Contact '
  end

  def contact_submit
    if ! params[:user_email] or params[:user_email].empty?
      flash[:notice] = "Email address required"
      redirect_to :action => "contact" and return
    end

    case params[:message_regarding]
      when 'general_support' then recipient = 'support@gamelayers.com'
      when 'account_recovery' then recipient = 'support@gamelayers.com'
      when 'feedback' then recipient = 'support@gamelayers.com'
      when 'bug_submission' then recipient = 'support@gamelayers.com'
      when 'abuse' then recipient = 'support@gamelayers.com'
      when 'dmca_claim' then recipient = 'support@gamelayers.com'
    end

    # Send the new user a welcome message.	 
    Mailer.deliver_contact(
      :subject => 'The Nethernet Support Request',
      :recipients => recipient,
      :reply_to => params[:user_email],
      :body => {
        :user_version => params[:user_version],
        :login => params[:user_name],
        :email => params[:user_email],
        :regarding => params[:message_regarding],
        :body => params[:message_details],
      }
    )
    flash[:notice] = 'Message sent'

    redirect_to :action => 'contact_sent'
  end

  def contact_sent
    @page_title = 'Contact sent'
  end

  def dmca
    @page_title = 'The DMCA Policy for '
  end

	def versions
		@page_title = 'A Version History of '
	end
end
