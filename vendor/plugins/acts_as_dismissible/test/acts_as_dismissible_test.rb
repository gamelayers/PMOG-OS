$:.unshift(File.dirname(__FILE__) + '/../lib')

require File.dirname(__FILE__) + '/../../../../config/environment'
require 'test/unit'
require 'rubygems'
require 'breakpoint'
require 'action_controller/test_process'
require File.join(File.dirname(__FILE__), 'book_controller')

ActionController::Base.logger = nil
ActionController::Base.ignore_missing_templates = false
ActionController::Routing::Routes.reload rescue nil

ActionController::Routing::Routes.draw do |map|
  map.connect ':controller/:action/:id'
end

# Re-raise errors caught by the controller.
class BookController; def rescue_action(e) raise e end; end

class ActsAsDismissibleTest < Test::Unit::TestCase
  def setup
    @controller = BookController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_dismiss_valid_params
    get :optional_params
    assert assigns(:response).body =~ /Don't bug me/
    assert assigns(:response).body =~ /class="new_class"/
    assert assigns(:response).body =~ /cookie/
    assert assigns(:response).body =~ /style="width: 40em;"/
  end

  def test_dismiss_show
    get :index
    assert assigns(:response).body =~ /cookie/
  end
  
  def test_dismiss_prevent_show
    @request.cookies["hide_dismissible_cookie"] = CGI::Cookie.new("name" => "hide_dismissible_cookie", "value" => "1", "expires" => Time.local(2025, 10, 10)) 
    get :index
    assert assigns(:response).body !~ /cookie/
  end
  
  def test_dismiss_prevent_show_without_follow_cookie_set
    get :follow
    assert assigns(:response).body !~ /cookie_two/
  end

  def test_dismiss_show_follow_cookie
    @request.cookies["hide_dismissible_cookie_one"] = CGI::Cookie.new("name" => "hide_dismissible_cookie_one", "value" => "1", "expires" => Time.local(2025, 10, 10)) 
    get :follow
    assert assigns(:response).body =~ /cookie_two/
  end
  
end
