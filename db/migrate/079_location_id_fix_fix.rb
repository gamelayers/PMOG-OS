class LocationIdFixFix < ActiveRecord::Migration
  # i must have been tired :(
  def self.up
    Lightpost.destroy_all
    remove_column :lightposts, :location_id
    add_column :lightposts, :location_id, :string, :limit => 36
  end

  def self.down
    remove_column :lightposts, :location_id
    add_column :lightposts, :location_id, :string, :limit => 35
  end
end
