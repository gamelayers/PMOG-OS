class AddActiveToForums < ActiveRecord::Migration
  def self.up
    add_column :forums, :inactive, :boolean, :default => false
  end

  def self.down
    remove_column :forums, :inactive
  end
end
