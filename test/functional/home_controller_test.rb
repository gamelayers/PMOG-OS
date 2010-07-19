require File.dirname(__FILE__) + '/../test_helper'
require 'home_controller'

# Re-raise errors caught by the controller.
class HomeController; def rescue_action(e) raise e end; end

class HomeControllerTest < ActionController::TestCase
  
  fixtures :users
  
  def setup
    @controller = HomeController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new    
  end
  
  def test_index_without_login_should_redirect
    # The index should render the welcome action since we're not logged in
    get :index
    assert_response :success
    
    assert @response.body =~ /Join the Game/
  end

  def test_robots
    get :robots
    assert_response :success
    assert @response.body =~ /Disallow: \/admin\//
  end

  def test_deprecated_news_redirect
    get :deprecated_news
    assert_redirected_to "http://news.pmog.com"
  end
  
  def test_deprecated_news_feed_atom
    get :deprecated_news_feed_atom
    assert_redirected_to "http://news.pmog.com/feed/atom/"
  end
  
  def test_deprecated_index_xml
    get :deprecated_index_xml
    assert_redirected_to "http://news.pmog.com/feed/"
  end
  
  def test_deprecated_track
    get :deprecated_track
    assert_response :success
  end
end
