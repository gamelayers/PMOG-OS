class AddFbInventoryPref < ActiveRecord::Migration
  def self.up
    add_column :fb_users, :pref_inventory, :integer, :limit => 2, :default => 1
  end

  def self.down
    remove_column :fb_users, :pref_inventory
  end
end
