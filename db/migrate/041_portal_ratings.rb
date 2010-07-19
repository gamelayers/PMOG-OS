class PortalRatings < ActiveRecord::Migration
  def self.up
    add_column :portals, :average_rating, :integer, :default => 0
  end

  def self.down
    remove_column :portals, :average_rating
  end
end
