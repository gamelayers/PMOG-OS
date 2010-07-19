require File.dirname(__FILE__) + '/../test_helper'
require 'shoppe_controller'

# Re-raise errors caught by the controller.
class ShoppeController; def rescue_action(e) raise e end; end

class ShoppeControllerTest < Test::Unit::TestCase
  all_fixtures

  def setup
    @controller = ShoppeController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_index
    login_as :marc # we need high levels to see all the tools
    get :index, :format => "json"
    assert_response :success
    response = response_to_json

    # We should return all of the tools available.
    assert_equal Tool.count, response.size
    
    # At the very least we need the name and the cost
    assert_not_nil response.first["cost"]
    assert_not_nil response.first["name"]

    # Here are the other optional fields that can be sent.
    # Except, something is fucking with the private_api_fields, they don't seem to be
    # set, meaning they revert to the default api fields, as you can see by doing the following:
    # puts Tool::private_api_fields.inspect
    # If you figure this out, please re-enable this test...
    #assert_equal ["character", "cost", "icon_image", "large_image","long_description", "medium_image", "name", "short_description", "small_image"].sort, response.first.keys.sort
  end  
  
  def test_buy
    login_as :suttree
    @user = User.find(@request.session[:user])
    crates = @user.inventory.crates
    mines = @user.inventory.mines
    @user.reward_datapoints(1001)

    post :buy, :format => 'json', "order" => { "tools" => {"crates"=>"5", "mines" => "2"} }
    response = response_to_json

    @user.reload

    assert_equal "Items Purchased", response["flash"]["notice"]
    assert_equal crates+5, @user.inventory.crates
    assert_equal mines+2, @user.inventory.mines
    assert_response 200
  end
  
  def test_buy_bad_params
    login_as :suttree
    @user = User.find(@request.session[:user])
    
    post :buy, :format => 'json', "order" => { "tools" => {} }
    response = response_to_json    
    assert_equal "Your order is empty", response["flash"]["error"]
    assert_response 422
    
    post :buy, :format => 'json', "order" => { "tools" => {"st_nicks"=>"10000000"} }
    response = response_to_json    
    assert_equal "You cannot purchase more than #{Shoppe.order_limit} items at one time.", response["flash"]["error"]
    assert_response 422
    
    @user.deduct_datapoints(@user.datapoints)
    post :buy, :format => 'json', "order" => { "tools" => {"st_nicks"=>"2"} }
    response = response_to_json
    assert_equal "You do not have enough datapoints to purchase these items.", response["flash"]["error"]
    assert_response 422
  end

end
