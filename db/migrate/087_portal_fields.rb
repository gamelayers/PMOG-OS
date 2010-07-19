class PortalFields < ActiveRecord::Migration
  def self.up
    remove_column :portals, :description
    add_column :portals, :title, :string
    add_column :portals, :nsfw, :boolean, :default => false
    add_column :portals, :charges, :integer, :default => 5
  end

  def self.down
    add_column :portals, :description, :text
    remove_column :portals, :title
    remove_column :portals, :nsfw
    remove_column :portals, :charges
  end
end
