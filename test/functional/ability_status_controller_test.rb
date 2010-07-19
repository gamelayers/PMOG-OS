require File.dirname(__FILE__) + '/../test_helper'

class AbilityStatusesControllerTest < ActionController::TestCase
  fixtures :users, :user_levels, :tools, :levels, :badges, :inventories, :ability_statuses

  def setup
    @suttree = users(:suttree)
    @suttree.inventory.set :armor, 1
    # fixture has no armor equipped
  end

  def test_should_equip_armor
    login_as :suttree

    assert_difference lambda{@suttree.inventory.reload.armor}, :call, -1 do
      put :toggle_armor, :format => 'json'
    end

    json_response = response_to_json
    json_response["flash"]["notice"] == "You are now protected!"
    assert_response 201
  end

  def test_should_display_error_when_equip_armor_fails
    login_as :suttree
    @suttree.inventory.set :armor, 0

    put :toggle_armor, :format => 'json'

    json_response = response_to_json
    assert json_response["flash"]["error"] == "You don't have any armor!"
    assert_response 201
  end
end
