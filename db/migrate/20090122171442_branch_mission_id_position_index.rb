class BranchMissionIdPositionIndex < ActiveRecord::Migration
  def self.up
    execute( "CREATE INDEX idx_mission_id_position ON branches(mission_id, position)" )
  end

  def self.down
    execute( "ALTER TABLE branches DROP INDEX idx_mission_id_position" )
  end
end
