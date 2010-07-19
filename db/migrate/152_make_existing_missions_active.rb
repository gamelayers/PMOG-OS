class MakeExistingMissionsActive < ActiveRecord::Migration
  def self.up
    @missions = Mission.find_with_inactive(:all)
    @missions.each do |mission|
      mission.activate!
    end
  end

  def self.down
  end
end
