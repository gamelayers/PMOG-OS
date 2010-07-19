require File.dirname(__FILE__) + '/../test_helper'
require 'missions_controller'

# Re-raise errors caught by the controller.
class MissionsController; def rescue_action(e) raise e end; end

class MissionsControllerTest < ActionController::TestCase
  fixtures :users

  def setup
    @controller = MissionsController.new
    super
  end
  
  # Some odd errors with tests buddy.
#  def test_index_without_login
#    get :index
#    assert_response :success
#    
#    assert_select "title", "Missions on PMOG"
#  end
#  
#  def test_index_with_login
#    login_as :pmog
#    get :index
#    assert_response :success
#    
#    assert_select "title", "Missions on PMOG"
#  end
  
  def test_new_without_login
    get :new
    assert_redirected_to :controller => 'sessions', :action => 'new'
  end
  
  # Removed per #963 but leaving it here in case we add similar functionality back
  # def test_destroy_rjs
  #   # Login as any user
  #   login_as :k41d3n
  #   
  #   # Make a reference instance to the user
  #   @user = User.find(@request.session[:user])
  #   
  #   # Create a new draft, which we'll destroy
  #   mission = Mission.new(:name => "Test Remove RJS", :description => "Testing the remove function", :user => @user)
  #   mission.save
  #   
  #   # Sanity check the existance of the mission object
  #   assert_not_nil mission
  #   
  #   # Destroy it
  #   get :destroy, :id => mission.url_name
  #   
  #   # Assert the rjs template does it's job
  #   assert_rjs :remove, "mission_#{mission.id}"
  #   assert_rjs :visual_effect, :highlight, "mission_list", :duration => '2'
  #   
  #   # Get the mission again to make sure it was deleted
  #   mission = Mission.find_with_inactive(:first, :conditions => { :name => "Test Remove RJS" } )
  #   
  #   # Assert that the mission no longer exists after we've destroyed it.
  #   assert_nil mission
  # end
  
  def test_toggle_nsfw_rjs
    # Login as any user
    login_as :marc
    
    # Make a reference instance to the user
    @user = User.find(@request.session[:user])
    
    # Create a new draft, which we'll destroy
    mission = Mission.new(:name => "Test Toggle NSFW RJS", :description => "Testing the remove function", :user => @user)
    # Activate the mission so the mission controller can find it as if it were a real published mission
    mission.activate!
    mission.save!
    
    # Make sure it's not already nsfw
    assert !mission.is_nsfw?
    
    # Toggle the nsfw via the toggle_nsfw action
    get :toggle_nsfw, :id => mission.url_name, :nsfw => "true"
    
    # Check the resulting RJS behavior
    #assert_rjs :replace_html, "toggle_nsfw"
    #assert_rjs :visual_effect, :highlight, "toggle_nsfw", :duration => 4
    #assert_rjs :visual_effect, :fade, "toggle_nsfw", :duration => 4
    
    # Get the mission again to ensure it was marked NSFW
    mission = Mission.find_by_name("Test Toggle NSFW RJS")
    assert mission.is_nsfw? == true
  end
  
  def test_add_tags
    login_as :marc
    
    # Make a reference instance to the user
    @user = User.find(@request.session[:user])
    dp = @user.datapoints
    
    # Create a new draft, which we'll destroy
    mission = Mission.new(:name => "Test Add Tags RJS", :description => "Testing the add_tags function", :user => @user)
    mission.activate!
    mission.save!
    
    # Assert the mission has no tags now
    assert_equal 0, mission.tags.count
    
    # Add one new tag
    put :add_tag, :user_id => @user.id, :id => mission.url_name, :tag => {:name => "one"}
    
    # Check that the behavior for adding tags is called
    #assert_rjs :replace_html, "tags"
    #assert_rjs :visual_effect, :highlight, "taglist", :duration => 2
    
    # check that the mission now has one tag and validate the value
    mission.tags.reload
    assert_equal 1, mission.tags.count
    assert_equal "one", mission.tags.last.name
    assert_equal dp + 1, @user.reload.datapoints
    
    put :add_tag, :user_id => @user.id, :id => mission.url_name, :tag => {:name => "two, three, four"}
    
    # Check that the behavior for adding tags is called
    #assert_rjs :replace_html, "tags"
    #assert_rjs :visual_effect, :highlight, "taglist", :duration => 2
    
    # check that the mission now has one tag and validate the value
    assert_equal 4, mission.tags.count
    
  end
  
  def test_delete_tags
    login_as :marc
    
    # Make a reference instance to the user
    @user = User.find(@request.session[:user])
    
    # Create a new draft, which we'll destroy
    mission = Mission.new(:name => "Test Remove Tags RJS", :description => "Testing the remove_tags function", :user => @user)
    mission.activate!
    mission.save!
    
    # Assert the mission has no tags now
    assert_equal 0, mission.tags.count
    
    # Add some tags
    put :add_tag, :user_id => @user.id, :id => mission.url_name, :tag => {:name => "one, two, three, four"}
    
    # Check that the tags were added to the mission
    mission.tags.reload
    assert_equal 4, mission.tags.count
    
    # Get a reference to one of the tags
    tag = mission.tags.first
    
    # Delete it
    dp = @user.reload.datapoints
    delete :remove_tag, :user_id => @user.id, :id => mission.url_name, :tag_id => tag.id
    assert_equal dp + 1, @user.reload.datapoints
    
    # Check for the rjs behavior
    #assert_rjs :remove, "tag-#{tag.id}"
    #assert_rjs :visual_effect, :highlight, 'taglist', :duration => 2
    
    # Check that it was really deleted.
    assert_equal 3, mission.tags.count
  end
 
end
