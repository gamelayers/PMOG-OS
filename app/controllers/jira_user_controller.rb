class JiraUserController < ApplicationController
  
  before_filter :check_user
  
  def register
    @user = User.find_by_login(params[:user_id])

    if params[:user][:password] == "" or not @user.authenticated?(params[:user][:password])
      flash[:error] = "The password entered is incorrect or invalid"
      redirect_to :action => 'show' and return
    end

    error_response = "<p>There was an error registering your account. <a href=\"http://pmog.com/about/contact/\">contact support</a> to complete this process</p>"

    exists = User.check_for_user(@user.login)

    if exists
      @response = "<p>Your account is already registered with the hospital. You should be able to login with your PMOG username and password</p>"
      return
    end

    User.create_jira_user(@user.login, @user.email, params[:user][:password])
    exists = User.check_for_user(@user.login)

    if exists
      valid = User.validate_login_and_password(@user.login, params[:user][:password])

      if valid
        @response = "<p>Your account has been registered with the hospital. You should be able to login with your PMOG username and password</p>
        <p>Visit <a href=\"http://hospital.pmog.com\">the hospital</a> to submit issues or request a new feature</p>"
      else
        @response = error_response
      end
    else
      @response = error_response
    end
  end
  
  private
  
  def check_user
    if current_user.login != params[:user_id]
      flash[:error] = "That's not yours!"
      redirect_to "/"
    end
  end
  
end
