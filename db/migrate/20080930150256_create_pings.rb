class CreatePings < ActiveRecord::Migration
  def self.up
    create_table :pings do |t|
      t.column :name, :string
      t.column :points, :integer
    end
    
    add_column(:users, :lifetime_pings, :integer, :default => 0)
    add_column(:users, :available_pings, :integer, :default => 0)
    p = Ping.create(:name => 'acq_to_ally', :points => 10)
    p = Ping.create(:name => 'acq_to_rival', :points => 15)
    p = Ping.create(:name => 'ally_loots_crate', :points => 10)
    p = Ping.create(:name => 'rival_trips_mine', :points => 10)
    p = Ping.create(:name => 'st_nick_rival', :points => 10)
    p = Ping.create(:name => 'acq_takes_mission', :points => 10)
    p = Ping.create(:name => 'send_pmail', :points => 1)
    p = Ping.create(:name => 'comment_mission', :points => 2)
    p = Ping.create(:name => 'rate_mission', :points => 2)
    p = Ping.create(:name => 'rate_portal', :points => 4)
  end

  def self.down
    drop_table :pings
    remove_column(:users, :lifetime_pings)
    remove_column(:users, :available_pings)
  end
end
