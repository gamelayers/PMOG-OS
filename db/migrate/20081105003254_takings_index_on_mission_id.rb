class TakingsIndexOnMissionId < ActiveRecord::Migration
  def self.up
    add_index :takings, :mission_id
  end

  def self.down
    remove_index :takings, :mission_id
  end
end
