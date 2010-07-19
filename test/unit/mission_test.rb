require File.dirname(__FILE__) + '/../test_helper'

class MissionTest < Test::Unit::TestCase
  fixtures :missions, :misc_actions, :game_settings, :locations, :users, :user_levels, :pings
  
  def setup
    super
  end
  
  def test_pmog_mission
    # Get the mission we know is the pmog mission and assert that it is a pmog mission
    mission = Mission.find_by_name("Pmog Only Mission")  
    assert mission.pmog_mission?
    
    # Change the pmog mission to a non pmog mission and assert that it isn't.
    mission.unmake_pmog!
    assert !mission.pmog_mission?
    
    # Get a mission we know isn't a pmog mission and assert as much
    mission = Mission.find_by_name("wercw")
    assert !mission.pmog_mission?
    
    # Change the non pmog mission to a pmog mission and assert it is.
    mission.make_pmog!
    assert mission.pmog_mission?
  end
  
  def test_taking_mission
    user = users(:suttree)
    mission = Mission.find_by_name("wercw")  
    taken = mission.users.size
    user_taken = user.missions.completed.size
    
    mission.users << user
    
    assert_equal (taken + 1), mission.users.size
    assert_equal (user_taken + 1), user.missions.completed.size
  end
  
  def test_is_tested_method
    # Get a user and a mission
    user = users(:suttree)
    mission = Mission.new(:name => "Test the Test yo.", :description => "This too, is just a test", :user => user)
    
    # Sanity check that the mission has no users
    assert_equal 0, mission.users.size
    
    # Check that the is_tested? method doesn't report true when the user hasn't tested it
    assert !mission.is_tested?
    
    # Add our user to the mission (also the author...)
    mission.users << user
    
    # Check that the mission has 1 user
    assert_equal 1, mission.users.size
    
    # Check that the model returns true for is_tested? as there is one user and it's also the author.
    assert mission.is_tested?
  end
  
  def test_publish_mission_updates_created_at
    
    # Get a user to assign as the mission owner
    user = users(:suttree)
    
    # Create a new mission
    mission = Mission.new(:name => "test", :description => "whatchu lookin' at?", :user => user)
    
    # Save it. This is important because it's where the mission record gets stamped with a 'created_at" date
    mission.save
    
    # Mark the created_at time in this variable so we can check aganst it to make sure publishing changes the 
    # created_at time.
    created_time = mission.created_at
    
    # Make sure we've got some time elapsed
    sleep(2)
    
    # Publish the mission, this should active it and update the timestamp to the current time (or the time the publish was made)
    mission.publish
    
    # Make sure the current created_at of the mission is updated
    assert mission.created_at > created_time
  end
  
  def test_has_info
    user = users(:suttree)
    
    mission = Mission.new(:name => "Testing has_info we are", :description => "Blargity Blarg blarg", :user => user)
    mission.save
    
    assert mission.has_info?
  end
  
  def test_name_and_description_exists_validation
    user = users(:suttree)
    
    mission = Mission.new(:user => user)
    
    assert !mission.valid?, "Mission should raise invalid errors on Name and Description"
    assert_equal "can't be blank", mission.errors.on(:name)
    assert_equal "can't be blank", mission.errors.on(:description)
  end
  
  def test_validate_branch_count
    user = users(:suttree)
    mission = Mission.new(:name => "Test Branch Count", :description => "Testing the count of branches.", :user => user)
    
    assert mission.valid?, "Mission should be valid with a name, description and user"
    
    mission.saving_lightposts = true
    
    assert_raises(ActiveRecord::RecordInvalid) do
      mission.save!
    end
  end
  
  def test_unique_url_name
    user = users(:suttree)
    
    mission = Mission.create(:name => "Unique URL Name", :description => "Testing the uniqueness of url names", :user => user)
    assert_equal false, mission.is_active
    assert_equal "unique_url_name", mission.url_name
    
    mission = Mission.create(:name => "Unique URL Name", :description => "Testing the uniqueness of url names", :user => user)
    assert_equal false, mission.is_active
    assert_equal "unique_url_name_", mission.url_name
    
  end
  
  def test_reward_datapoints_to_creator
    user = users(:marc)
    
    mission = missions('mission_8302ddf0-eaf6-11dc-a561-001b63928f8d')
    
    # Put the mission creator's dp to a known level
    mission.user.datapoints = 0
    
    # Set the mission rating to 0 which would be the default rating
    # Assert that it rewards 4 dp
    rate_and_reward(mission, user, 0)
    assert_equal 4, mission.user.datapoints

    # Set the rating to 1.
    # Assert that t rewards 4 dp
    rate_and_reward(mission, user, 1)
    
    assert_equal 8, mission.user.datapoints 
    
    # Set the rating to 2
    # Assert that t rewards 6 dp
    rate_and_reward(mission, user, 2)
    
    assert_equal(14, mission.user.datapoints)
    
    # Set the rating to 3
    # Assert that t rewards 8 dp
    rate_and_reward(mission, user, 3)
    
    assert_equal(22, mission.user.datapoints)
    
    # Set the rating to 4
    # Assert that t rewards 10 dp
    rate_and_reward(mission, user, 4)
    
    assert_equal(32, mission.user.datapoints)
    
    # Set the rating to 5
    # Assert that t rewards 12 dp
    rate_and_reward(mission, user, 5)
    
    assert_equal(44, mission.user.datapoints)
  end
  
  # Testing the switch from habtm to hmt
  def test_missions_users
    @user = users(:suttree)
    @mission = Mission.find :first
        
    # Make sure this mission has no users or missionatings
    @mission.users = []
    Missionating.destroy_all
    assert_equal [], @mission.users
    assert_equal [], Missionating.find(:all)
   
    # Now assign a user and make sure everything lines up
    @mission.users << @user
    assert_equal @mission.users.size, 1
    assert_equal Missionating.find(:first).created_at.to_date, Time.now.utc.to_date
  end

  private
  
  def rate_and_reward(mission, user, rating) 
    mission.average_rating = rating
    
    mission.reward_creator(user)
  end
  
end
