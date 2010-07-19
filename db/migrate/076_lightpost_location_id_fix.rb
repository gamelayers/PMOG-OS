class LightpostLocationIdFix < ActiveRecord::Migration
  def self.up
    remove_column :lightposts, :locationid
    add_column :lightposts, :location_id, :string, :limit => 35
  end

  def self.down
    add_column :lightposts, :locationid, :string, :limit => 35
    remove_column :lightposts, :location_id
  end
end
