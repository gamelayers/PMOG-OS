class DataPoints < ActiveRecord::Migration
  def self.up
    add_column :users, :datapoints, :integer, :default => 0
  end

  def self.down
    remove_column :users, :datapoints
  end
end
