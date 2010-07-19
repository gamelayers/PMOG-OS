require File.dirname(__FILE__) + '/../test_helper'
require 'st_nicks_controller'

class StNicksControllerTest < ActionController::TestCase
  fixtures :users, :st_nicks, :levels, :inventories

  def setup
    super
    @suttree = users(:suttree)
    @alex = users(:alex)

    @alex.inventory.set :st_nicks, 6

    @params = { :user_id => @suttree.login }
  end
  
  def test_max_st_nicks
    # Attach 2 nicks with the model before we test the controller
    2.times do
      StNick.create_and_attach(@alex, @params)
    end

    login_as :alex

    # Confirm that the controller works
    put :attach, @params, :format => "json"

    assert_equal 3, @suttree.st_nicks.reload.size
    
    # Attach 2 more St Nicks (to make a total of 5)
    2.times do
      StNick.create_and_attach(@alex, @params)
    end
    
    # Confirm that the controller fails gracefully
    put :attach, @params, :format => "json"

    assert_equal 5, @suttree.st_nicks.reload.size
    assert_response 401
  end
end
