require File.dirname(__FILE__) + '/../test_helper'

class QueuedMissionTest < ActiveSupport::TestCase
  fixtures :users, :missions
  
  def setup
    @user = users(:pmog)
    @mission = missions(:pmog_only_mission)
  end
  
  def test_deposit
    QueuedMission.deposit(@user, @mission)
    assert QueuedMission.exists?(@user, @mission)
  end
  
  def test_should_not_deposit_a_non_published_mission
    @mission = Mission.find(:first)
    @mission.update_attribute(:is_active, false)
    assert_no_difference(QueuedMission, :count) do
      assert_raise ActiveRecord::RecordInvalid do
        @results = QueuedMission.deposit(@user, @mission)
      end
    end
    
  end
end
