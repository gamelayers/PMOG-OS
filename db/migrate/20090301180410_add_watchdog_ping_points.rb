class AddWatchdogPingPoints < ActiveRecord::Migration
  def self.up
    Ping.create(:name => 'watchdogged_rival', :points => 10)
  end

  def self.down
    p = Ping.find_by_name('watchdogged_rival')
    p.destroy
  end
end
