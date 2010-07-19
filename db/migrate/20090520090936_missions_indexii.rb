class MissionsIndexii < ActiveRecord::Migration
  def self.up
    add_index :mission_stats, [:created_at, :action, :context]
    add_index :mission_stats, [:created_at, :action, :user_id]
  end

  def self.down
    remove_index :mission_stats, [:created_at, :action, :user_id]
    remove_index :mission_stats, [:created_at, :action, :context]
  end
end
