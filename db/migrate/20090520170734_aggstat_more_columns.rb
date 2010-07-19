class AggstatMoreColumns < ActiveRecord::Migration
  def self.up
    add_column :aggstats, :user_total, :integer, :default =>0
    add_column :aggstats, :mission_total, :integer, :default =>0
    add_column :aggstats, :pmail_total, :integer, :default =>0
    add_column :aggstats, :events_total, :integer, :default =>0
    add_column :aggstats, :tld_total, :integer, :default => 0
  end

  def self.down
    remove_column :aggstats, :user_total
    remove_column :aggstats, :mission_total
    remove_column :aggstats, :pmail_total
    remove_column :aggstats, :events_total
    remove_column :aggstats, :tld_total
  end
end
