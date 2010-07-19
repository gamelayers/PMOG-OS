class AggStatAddActivity < ActiveRecord::Migration
  def self.up
    remove_column :aggstats, :users_connected_in
    add_column :aggstats, :users_first_time_connected, :integer, :default => 0
  end

  def self.down
    add_column :aggstats, :users_connected_in, :integer, :default => 0
    remove_column :aggstats, :users_first_time_connected
  end
end
