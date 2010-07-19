class AddCroppingToAssets < ActiveRecord::Migration
  def self.up
    add_column :assets, :crop_x1, :integer
    add_column :assets, :crop_y1, :integer
    add_column :assets, :crop_x2, :integer
    add_column :assets, :crop_y2, :integer
  end

  def self.down
    remove_column :assets, :crop_x1
    remove_column :assets, :crop_y1
    remove_column :assets, :crop_x2
    remove_column :assets, :crop_y2
  end
end
