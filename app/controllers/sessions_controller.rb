# This controller handles the login/logout function of the site.
class SessionsController < ApplicationController
  # Note that we skip the CSRF check for +create+ (see lib/forgery_protection_extension.rb)

  #skip_before_filter :login_required

  def index
    respond_to do |format|
      format.html do
        # if the user tries to access /sessions and they aren't
        # logged in already, redirect to the login form
        if session[:user].nil?
          redirect_to '/sessions/new'
        else
          # If they are logged in, kick them back to the profile page
          redirect_to '/users/' + current_user.login
        end
      end
      format.json do
        if session[:user].nil?
          flash[:error] = "Not logged in!"
          response.headers["Content-Type"] = "text/json; charset=utf-8"
          render :json => flash.to_json, :status => 406
          flash.discard
        else
          flash[:notice] = "Already logged in!"
          response.headers["Content-Type"] = "text/json; charset=utf-8"
          render :json => render_full_json_response(:flash => flash_message), :status => 201
          flash.discard
        end
      end
    end
  end

  def show
    redirect_to '/'
  end

  # User logins take place here. There are some restrictions on failed login attempts, though.
  # This is designed to stop someone scripting a login attack which just fires passwords at our
  # server until they get in - duncan 8/01/08
  # - if a users' account is locked, they cannot attempt a login
  # - if a user has attempted to login and failed, they must wait to try again
  # - if there are more than X login attempts, their account will be locked.
  def create
    # Find the user, but only for tracking login attempts
    if (params[:login].match(/^\s*(?:(?:[^,@\s]+)@(?:(?:[-a-z0-9]+\.)+[a-z]{2,}\s*(,\s*|\z)))+$/i))
      attempted_user = User.find_by_email(params[:login])
    else
      attempted_user = User.find(:first, :conditions => {:login => params[:login]})
    end

    # Deny locked accounts and rate limit login attempts (the more times they login
    # incorrectly, the longer they have to wait). Otherwise, attempt a login.
    if attempted_user && attempted_user.locked?
      flash[:notice] = "Your account has been locked for security reasons. Please contact us to resolve this issue."
      @account_locked = true
      respond_to do |format|
        format.json { render :json => create_error_overlay(flash[:notice]), :status => 403 }
        format.html { render :action => :locked }
      end
      return
    elsif attempted_user &&
          attempted_user.last_login_attempt &&
          attempted_user.last_login_attempt < attempted_user.tz.now &&
          (attempted_user.last_login_attempt + attempted_user.login_delay.seconds) > attempted_user.tz.now
      # Note that in the above conditional we have a check to make sure the users' last login attempt
      # is not in the future. I've seen this happen and it means players can never login, so we
      # check for it now - duncan 07/02/09
      flash[:notice] = "Please wait a little longer before trying to log in again."
      @account_limited = true
      respond_to do |format|
        format.json { render :json => create_error_overlay(flash[:notice]), :status => 423 }
        format.html { render :action => :new }
      end
      return
    elsif attempted_user
      # Attempt to login
      self.current_user = User.authenticate(attempted_user.login, params[:password])
    end

    if logged_in?
      attempted_user.record_login_attempt(request.remote_ip, true) unless attempted_user.nil?
      session[:user] = self.current_user.id

      self.current_user.remember_me
      cookies[:auth_token] = { :value => self.current_user.remember_token , :expires => self.current_user.remember_token_expires_at }

      flash[:notice] = "Logged in successfully"
      respond_to do |format|
        format.html { redirect_back_or_default('/') }
        format.ext  {
          if params[:format] && params[:format].to_s == 'ext'
            flash[:notice] = "You have been authenticated."
            redirect_back_or_default('/hud.ext')
          else
            redirect_back_or_default('/')
          end
        }
        format.js { render :json => create_new_session_overlay }
        format.json { render :json => create_new_session_overlay }
      end
    else
      attempted_user.record_login_attempt(request.remote_ip, false) if attempted_user
      flash[:error] = "Sorry, please try again"
      respond_to do |format|
        format.html { redirect_to :controller => 'sessions', :action => 'new' }
        format.ext { redirect_to :controller => 'sessions', :action => 'new' }

        error_message = "Login failed!"
        format.json { render :json => create_error_overlay(error_message), :status => 406 }
      end
    end
  end

  def destroy
    self.current_user.forget_me if logged_in?
    cookies.delete :auth_token
    reset_session
    flash[:notice] = "You have been logged out."
    respond_to do |format|
      format.html {
        redirect_back_or_default('/')
      }
      format.json {
        render :json => flash.to_json, :status => 200
        flash.discard
      }
    end
  end

  def password_reset
    #current_user = User.find_by_email(params[:email])
    @user = User.find_by_login(params[:user])

    if @user.email != params[:email]
      flash[:notice] = "That user and email don't match"
      redirect_to :action => "forgotten_password"
    else
      reset
      return
    end
  end

  def answer_question_reset
    @user = User.find_by_login(params[:user])

    begin
      if @user.email.nil? and params[:email].empty?
        flash[:error] = "You must enter your email address"
        render :action => "forgotten_password"
        return
      elsif @user.email.nil? or @user.email.empty? and params[:email]
        @user.email = params[:email]
        @user.save!
        @user.reload
      end

      if @user.user_secret.answer?(params[:answer])
        reset
        return
      else
        flash[:error] = "Incorrect answer. Please try again."
        @failed_attempt = true
        render :action => "forgotten_password"
      end
    rescue Exception => e
      @user.email = nil
      render :action => "forgotten_password"
    end
  end

  def retrieve_user
    @user = User.find_by_login(params[:login])

    respond_to do |format|
      format.html {
        if @user.nil?
          flash[:error] = "There is no player named #{params[:login]}"
        end

        render :action => "forgotten_password"
      }
    end
  end

  private

  def reset
    unless @user.nil?
      # If there is no email in the params, get it from the user
      recipient = params[:email]

      if recipient.nil? or recipient.empty?
        recipient = @user.email
      end

      chars = ('a'..'z').to_a + ('A'..'Z').to_a + ('1'..'9').to_a
      @user.password = ''
      1.upto(15) { |i| @user.password << chars[rand(chars.size-1)] }
      @user.password_confirmation = @user.password

      Mailer.deliver_password_reset(
        :subject => "The Nethernet Password Reset",
        :recipients => recipient,
        :body => {
                    :login => @user.login,
                    :email => params[:email],
                    :password => @user.password
                  }
      )

      @user.save
      flash[:notice] = "Your password has been reset and emailed to you"
      redirect_to :action => "password_sent"
    end
  end
end
