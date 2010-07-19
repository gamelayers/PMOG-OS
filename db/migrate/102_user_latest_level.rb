class UserLatestLevel < ActiveRecord::Migration
  def self.up
    add_column :users, :current_level, :integer, :default => 1
    add_index :users, :current_level
  end

  def self.down
    remove_column :users, :current_level
  end
end
