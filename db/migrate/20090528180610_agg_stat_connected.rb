class AggStatConnected < ActiveRecord::Migration
  def self.up
    add_column :aggstats, :users_connected, :integer, :default =>0
  end

  def self.down
    remove_column :aggstats, :users_connected
  end
end
