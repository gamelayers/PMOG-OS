class AddLevelToReward < ActiveRecord::Migration
  def self.up
    add_column :rewards, :level, :integer
  end

  def self.down
    remove_column :rewards, :level
  end
end
