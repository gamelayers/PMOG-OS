class PortalDescriptions < ActiveRecord::Migration
  def self.up
    add_column :portals, :description, :text
  end

  def self.down
    remove_column :portals, :description
  end
end
