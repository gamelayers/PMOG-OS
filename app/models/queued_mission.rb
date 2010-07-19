# == Schema Information
# Schema version: 20081220201004
#
# Table name: queued_missions
#
#  id         :string(36)    not null, primary key
#  user_id    :string(36)    not null
#  mission_id :string(36)    not null
#  created_at :datetime      
#  updated_at :datetime      
#

class QueuedMission < ActiveRecord::Base
  belongs_to :user
  belongs_to :mission

  def before_create
    self.id = create_uuid
  end
  
  def before_save
    raise ActiveRecord::RecordInvalid.new(mission) unless mission.is_active?
  end
  
  def self.exists?(user, mission)
    not find_by_user_id_and_mission_id(user, mission).nil?
  end

  def self.deposit(user, mission)
    return if user.nil? or mission.nil?
    unless QueuedMission.exists?(user, mission)
      create(:user => user, :mission => mission)
      user.clear_cache('queued_missions_history')
    end
  end

  # Delete or "de-queue"
  def self.dequeue(user, mission)
    if QueuedMission.exists?(user, mission)
      transaction do
        destroy(find_by_user_id_and_mission_id(user, mission))
        user.clear_cache('queued_missions_history')
      end
    end
  end
end
