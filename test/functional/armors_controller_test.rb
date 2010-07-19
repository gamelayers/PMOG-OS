require File.dirname(__FILE__) + '/../test_helper'
require 'armors_controller'

# Re-raise errors caught by the controller.
class ArmorsController; def rescue_action(e) raise e end; end

# starring suttree as bedouin bobert
class ArmorsControllerTest < ActionController::TestCase
  fixtures :users, :user_levels, :tools, :levels, :badges, :inventories, :ability_statuses
  
  def setup
    @suttree = users(:suttree)
    @suttree.inventory.set :armor, 1
  end
  
  def test_should_equip_armor
    login_as :suttree

    old_count = @suttree.inventory.armor

    put :equip, :format => 'json'

    json_response = response_to_json
    json_response["flash"]["error"] == "This API endpoint is deprecated."
    assert_response 422 
  end
  
  def test_should_unequip_armor
    login_as :suttree
    
    put :unequip, :format => 'json'

    json_response = response_to_json
    json_response["flash"]["error"] == "This API endpoint is deprecated."
    assert_response 422
  end

  # We have an obtuse bug whereby equipping or unequipping armor
  # causes subsequent tool uses to fail, because it sends
  # back a location id. This test should ensure that the location
  # id is always null
  #def test_using_armor_should_not_return_location_id
  #  login_as :suttree
  #  @suttree.inventory.set( :armor, 5 )
  #
  #  put :equip, :format => 'json'
  #
  #  json_response = ActiveSupport::JSON.decode(@response.body)
  #  assert_equal nil, json_response['id']
  #end
end
