class RetroactivePathmakerCp < ActiveRecord::Migration
  def self.up
    Mission.all do |mission|
      if !mission.user.nil? && !mission.user.user_level.nil?
        mission.user.user_level.pathmaker_cp += 50
        mission.user.user_level.save
      end
    end
  end

  def self.down
  end
end
