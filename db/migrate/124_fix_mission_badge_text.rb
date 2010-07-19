class FixMissionBadgeText < ActiveRecord::Migration
  def self.up
    five_missions = Badge.find_by_name('5 Missions')
    five_missions.description = "For players who create 5 missions"
    five_missions.save
    
    fifteen_missions = Badge.find_by_name('15 Missions')
    fifteen_missions.description = "For players who create 15 missions"
    fifteen_missions.save
    
    thirty_missions = Badge.find_by_name('30 Missions')
    thirty_missions.description = "For players who create 30 missions"
    thirty_missions.save
  end

  def self.down
  end
end
