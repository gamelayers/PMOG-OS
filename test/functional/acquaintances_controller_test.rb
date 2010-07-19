require File.dirname(__FILE__) + '/../test_helper'
require 'acquaintances_controller'

# Re-raise errors caught by the controller.
class AcquaintancesController; def rescue_action(e) raise e end; end
  
class AcquaintancesControllerTest < ActionController::TestCase
  fixtures :users
  
  def setup
    super   
  end
  
  def test_show
    login_as :suttree
    get :show, :id => 'suttree', :format => 'json'
    
    assert_response :success
    json_response = response_to_json
    assert_equal ["allies", "contacts", "recently_active", "rivals"], json_response.keys.sort
  end
end
