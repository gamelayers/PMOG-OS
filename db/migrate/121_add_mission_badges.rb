class AddMissionBadges < ActiveRecord::Migration
  def self.up
    Badge.create( :name => "5 Missions", :description => "For players who take and complete 5 missions").save
    Badge.create( :name => "15 Missions", :description => "For players who take and complete 15 missions").save
    Badge.create( :name => "30 Missions", :description => "For players who take and complete 30 missions").save
  end

  def self.down
  end
end
