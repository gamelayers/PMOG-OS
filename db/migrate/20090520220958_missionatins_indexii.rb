class MissionatinsIndexii < ActiveRecord::Migration
  def self.up
    add_index :missionatings, [:created_at, :user_id]
  end

  def self.down
    remove_index :missionatings, [:created_at, :user_id]
  end
end
