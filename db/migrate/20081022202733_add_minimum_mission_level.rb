class AddMinimumMissionLevel < ActiveRecord::Migration
  def self.up
    add_column :missions, :minimum_level, :integer, :default => 1
  end

  def self.down
    remove_column :missions, :minimum_level
  end
end
