class CleanUpPings < ActiveRecord::Migration
  def self.up
    # fuck it, we're cleaning house
    Ping.all do |p|
      p.destroy
    end

    Ping.create(:name => 'Aid Ally', :points => 5)
    Ping.create(:name => 'Damage Rival', :points => 5)
    Ping.create(:name => 'Rating', :points => 5)
    Ping.create(:name => 'Reply', :points => 2)
    Ping.create(:name => 'New Post', :points => 10)
    Ping.create(:name => 'Make Contact', :points => 10)
  end

  def self.down
    # stupid fucker, write your downs

    Ping.all do |p|
      p.destroy
    end

    Ping.create(:name => 'acq_to_ally', :points => 10)
    Ping.create(:name => 'acq_to_rival', :points => 15)
    Ping.create(:name => 'ally_loots_crate', :points => 10)
    Ping.create(:name => 'rival_trips_mine', :points => 10)
    Ping.create(:name => 'st_nick_rival', :points => 10)
    Ping.create(:name => 'acq_takes_mission', :points => 10)
    Ping.create(:name => 'send_pmail', :points => 1)
    Ping.create(:name => 'comment_mission', :points => 2)
    Ping.create(:name => 'rate_mission', :points => 2)
    Ping.create(:name => 'rate_portal', :points => 4)
  end
end
