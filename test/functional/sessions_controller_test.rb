require File.dirname(__FILE__) + '/../test_helper'
require 'sessions_controller'

# Re-raise errors caught by the controller.
class SessionsController; def rescue_action(e) raise e end; end

# Subclass the test Request object, so that we can test switching IP
# addresses. Note that overwriting @request using instance_eval won't work
# since Rails uses request rather than @request.
# From http://madhatted.com/2007/5/31/yes-geocode-but-save-your-caches
class IpSwitchingController < ActionController::TestRequest
  def remote_ip
    @remote_ip || set_remote_ip
  end

  def set_remote_ip(ip = '127.0.0.1')
    @remote_ip = ip
  end
end

class SessionsControllerTest < ActionController::TestCase
  fixtures :users

  def setup
    super
    @request = IpSwitchingController.new
    @response = ActionController::TestResponse.new
    @request.set_remote_ip('127.0.0.1')
  end

  def test_not_logged_in_redirect
    get :index
    assert_redirected_to '/sessions/new'
  end

  def test_logged_in_redirect
    login_as :pmog
    get :index
    assert_redirected_to :controller => 'users', :action => 'show', :id => 'pmog' #FIXME temporary until we have a dashboard
  end

  def test_valid_new_session_form
    get :new
    assert_template 'new'
    assert_select "title", /The Nethernet/

    submit_form "login" do |form|
      form.login = 'pmog'
      form.password = 'itsasekrit'
    end

    assert_redirected_to :controller => 'home', :action => 'index'

    assert session[:user]

    assert_equal "Logged in successfully", flash[:notice]
  end

  def test_invalid_new_session_form
    get :new
    assert_template 'new'
    assert_select "title", /The Nethernet/

    submit_form "login" do |form|
      form.login = 'pmog'
      form.password = 'boo'
    end

    assert_redirected_to :controller => 'sessions', :action => 'new'

    assert_equal "Sorry, please try again", flash[:error]
  end

  def test_restful_login
    post :create, :login => 'pmog', :password => 'itsasekrit'

    assert_redirected_to :controller => 'home', :action => 'index'

    assert session[:user]
  end

  def test_should_skip_authenticity_token_filter_on_create_for_javascript
    # Enable csrf checks just for this test
    @controller.class.module_eval do
      self.allow_forgery_protection = true
    end

    @controller.instance_eval do
      def current_user_data
        return Hash.new
      end
    end

    # Should block normal posts.
    assert_raises(ActionController::InvalidAuthenticityToken) do
      post :create, :login => 'pmog', :password => 'itsasekrit'
      assert_redirected_to('/')
    end

    # Should allows posts using JS to proceed.
    post :create , :format => 'js', :hud => 'true', :login => 'pmog', :password => 'itsasekrit'
    json_response = ActiveSupport::JSON.decode(@response.body)
    assert !json_response['version'].nil?
    assert !json_response['css_version'].nil?
    assert_response :success

    # And now disable the CSRF checks again
    @controller.class.module_eval do
      self.allow_forgery_protection = false
    end
  end

  def test_logout
    # Log in first
    post :create, :login => 'pmog', :password => 'itsasekrit'
    assert_redirected_to :controller => 'home', :action => 'index'
    assert session[:user]

    # Now log out
    post :destroy
    assert_redirected_to :controller => 'home', :action => 'index'
    assert ! session[:user]
    assert ! cookies[:auth_token]
  end

  # A successful login should
  # - reset the failed_login_attempts
  # - store the correct IP address
  # - update the last_login_attempt timestamp
  # - it should also update a key in memcached, but I can't really test that.
  def test_successful_login_tracking
    post :create, :login => 'pmog', :password => 'itsasekrit'
    assert_redirected_to :controller => 'home', :action => 'index'
    assert session[:user]

    u = User.find_by_login 'pmog'
    assert u.login_delay(5) == 5
    assert u.login_delay(10) == 10
    assert u.remote_ip == '127.0.0.1'
    assert u.failed_login_attempts == 0
    assert u.last_login_attempt > 10.seconds.ago
  end

  # An unsuccessful login should
  # - increment the failed_login_attempts
  # - store the correct IP address
  # - update the last_login_attempt timestamp
  # - lock the account if required
  # - it should also update a key in memcached, but I can't really test that.
  def test_unsuccessful_login_tracking
    post :create, :login => 'pmog', :password => 'wrong_password'
    assert_redirected_to :controller => 'sessions', :action => 'new'
    assert ! session[:user]
    assert ! cookies[:auth_token]

    u = User.find_by_login 'pmog'
    assert_equal u.login_delay(5), 5
    assert_equal u.login_delay(10), 10
    assert_equal u.remote_ip, '127.0.0.1'
    assert_equal u.failed_login_attempts, 1
    assert u.last_login_attempt > 10.seconds.ago

#    puts "\n\tSleeping before next login attempt..."
    sleep(5)
#    puts "\tAwake!"

    # Wait for the delay to expire, then try logging in unsuccessfully again
    # The delay should increase and we should be told to try again.
    post :create, :login => 'pmog', :password => 'wrong_password'
    assert ! session[:user]
    assert ! cookies[:auth_token]

    u = User.find_by_login 'pmog'
    assert_equal u.login_delay(5), 10
    assert_equal u.login_delay(10), 20
    assert_equal u.remote_ip, '127.0.0.1'
    assert_equal flash[:error], 'Sorry, please try again'
    assert_equal u.failed_login_attempts, 2
    assert u.last_login_attempt > 10.seconds.ago

    # Now just try logging in unsuccessfully without waiting
    # We should be told to wait, and the attempts and delay should not increase.
    post :create, :login => 'pmog', :password => 'wrong_password_again'
    assert ! session[:user]
    assert ! cookies[:auth_token]

    u = User.find_by_login 'pmog'
    assert assigns(:account_limited), true
    assert_equal u.login_delay(5), 10 # 2 failed attempts at 5 seconds each
    assert_equal u.login_delay(10), 20 # 2 failed attempts at 10 seconds each
    assert_equal u.remote_ip, '127.0.0.1'

    assert_equal flash[:notice], 'Please wait a little longer before trying to log in again.'
    assert_equal u.failed_login_attempts, 2
    assert u.last_login_attempt > 10.seconds.ago
  end

  # Locked accounts should not be allowed to login
  def test_locked_account_cannot_login
    u = User.find_by_login 'pmog'
    u.lock_account
    post :create, :login => 'pmog', :password => 'itsasekrit'
    assert_response 403
    assert_equal flash[:notice], "Your account has been locked for security reasons. Please contact us to resolve this issue."
    assert assigns(:account_locked), true
  end

  # Unlocking an account should allow it to login
  def test_unlocking_an_account_and_logging_in
    u = User.find_by_login 'pmog'
    u.unlock_account
    post :create, :login => 'pmog', :password => 'itsasekrit'
    assert_redirected_to :controller => 'home', :action => 'index'
    assert session[:user]
  end

  def test_extension_incorrect_login_status_code
    post :create, :format => 'json', :login => 'pmog', :password => 'wrong_password'
    assert_response 406
  end

  def test_extension_locked_acount_login_status_code
    u = User.find_by_login 'pmog'
    u.lock_account
    post :create, :format => 'json', :login => 'pmog', :password => 'itsasekrit'
    assert_response 403
  end

  def test_extension_delayed_login_status_code
    post :create, :format => 'json', :login => 'pmog', :password => 'wrong_password'
    post :create, :format => 'json', :login => 'pmog', :password => 'wrong_password_again'
    post :create, :format => 'json', :login => 'pmog', :password => 'wrong_password_once_again'
    assert_response 423
  end

  # A users ip address should be logged on a successful or unsuccessful login attempt
  # - would be nice to track the ip address stuff in memcached too, but....
  # However, this just doesn't work. I'll leave the code here but there tests aren't running - duncan 09/01/09
  def tmp_test_ip_address_tracking
    @request.set_remote_ip('127.0.0.1')
    u = User.find_by_login 'pmog'

    # A successful attempt should log the latest remote ip
    post :create, :login => 'pmog', :password => 'itsasekrit'
    assert_equal u.reload.remote_ip, '127.0.0.1'

    # Again with a different ip
    @request.set_remote_ip('158.152.1.58')
    post :create, :login => 'pmog', :password => 'itsasekrit'
    assert_equal u.reload.remote_ip, '158.152.1.58'

    # As should an unsuccesful attempt
    @request.set_remote_ip('158.152.1.43')
    post :create, :login => 'pmog', :password => 'wrong_password'
    assert_equal u.reload.remote_ip, '158.152.1.43'

    # Note that locked accounts and time-delayed accounts should not alter the remote ip
    @request.set_remote_ip('158.152.1.99')
    post :create, :login => 'pmog', :password => 'wrong_password_again'
    assert_equal u.reload.remote_ip, '158.152.1.43' # should NOT be 158.152.1.99

    u.lock_account
    @request.set_remote_ip('158.152.1.11')
    post :create, :login => 'pmog', :password => 'wrong_password_once_more'
    assert_equal u.reload.remote_ip, '158.152.1.43' # should NOT be 158.152.1.11
  end
end
