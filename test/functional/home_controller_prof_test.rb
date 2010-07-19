require File.dirname(__FILE__) + '/../profile_test_helper'
require File.dirname(__FILE__) + '/../test_helper'
require 'home_controller'

# This test uses ruby-prof and runs each test 10 times,
# creating a bunch of profiling files in tmp/profile/
# which we can use to investigate slow parts of the site - duncan 26/01/09
# See http://cfis.savagexi.com/2008/11/13/profiling-your-rails-application-take-two

# Re-raise errors caught by the controller.
class HomeController; def rescue_action(e) raise e end; end

class HomeControllerProfTest < ActionController::TestCase
  include RubyProf::Test

  fixtures :users, :brain_busters

  def setup
    @controller = HomeController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Profile the logged out home page, which should be the fastest we can get
  def test_profile_logged_out_home_page
    get :index
  end

  # Profile the logged in home page, which our players are likely to see a lot
  def test_profile_logged_in_home_page
    @request.session[:user] = User.find_by_login('suttree').id
    get :index
  end
end
