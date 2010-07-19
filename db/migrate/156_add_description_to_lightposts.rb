class AddDescriptionToLightposts < ActiveRecord::Migration
  def self.up
    add_column :lightposts, :description, :text
  end

  def self.down
    remove_column :lightposts, :description
  end
end
