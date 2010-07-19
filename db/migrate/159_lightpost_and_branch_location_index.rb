class LightpostAndBranchLocationIndex < ActiveRecord::Migration
  def self.up
    #add_index :branches, :location_id
    add_index :lightposts, :location_id
  end

  def self.down
    #remove_index :branches, :location_id
    remove_index :lightposts, :location_id
  end
end
