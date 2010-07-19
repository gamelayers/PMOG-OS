class AddIsActiveMissions < ActiveRecord::Migration
  def self.up
    add_column :missions, :is_active, :boolean, :default => false
  end

  def self.down
    remove_column :missions, :is_active
  end
end
