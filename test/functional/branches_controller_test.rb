require File.dirname(__FILE__) + '/../test_helper'

class BranchesControllerTest < ActionController::TestCase
  fixtures :missions, :branches, :users, :locations, :tools, :ability_statuses

  def setup
    super
    login_as :suttree
  end
  
  def test_should_read_more
    @mission = missions(:mission_with_long_text)
    xhr :get, :read_more, :mission_id => @mission.url_name, :id => @mission.branches.first.id
    assert_equal assigns(:show_long_description), true
    
    # This text appears at the end of the long descriptions and will only be returned if
    # all of the proceeding text is too, which means we are seeing the entire entry.
    assert @response.body =~ /ENDOFBRANCHDESCRIPTION/ 
    assert @response.body !=~ /read more/
    assert assigns(:next)
    assert !assigns(:previous) # This is the first stop on the mission so nothing to go back to.
    assert_response :success
  end
  
  # Ensure that bad missions or branches render the error overlay.
  def test_should_read_more_bad_params
    @mission = missions(:mission_with_long_text)
    xhr :get, :read_more, :mission_id => @mission.url_name, :id => 'bad branch id'
    assert @response.body =~ /Mission could not be found. Try, reloading your browser/
    assert_equal !assigns(:show_long_description), true    
    assert !assigns(:next)
    assert !assigns(:previous) # This is the first stop on the mission so nothing to go back to.
    assert_response :success

    xhr :get, :read_more, :mission_id => 'bad mission id', :id => @mission.branches.first.id
    assert @response.body =~ /Mission could not be found. Try, reloading your browser/
    assert_equal !assigns(:show_long_description), true    
    assert !assigns(:next)
    assert !assigns(:previous) # This is the first stop on the mission so nothing to go back to.
    assert_response :success
  end
end
