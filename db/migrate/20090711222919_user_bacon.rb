class UserBacon < ActiveRecord::Migration
  def self.up
    add_column :users, :bacon, :integer, :default => 0
    add_column :users, :max_bacon_per_buy, :integer, :default => 0
  end

  def self.down
    remove_column :users, :bacon
    remove_column :users, :max_bacon_per_buy
  end
end
