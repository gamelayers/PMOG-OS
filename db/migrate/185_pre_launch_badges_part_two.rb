class PreLaunchBadgesPartTwo < ActiveRecord::Migration
  def self.up
    group = Group.find_by_name 'URL/Surfing'

    Badge.create( :group_id => group.id, :name => "KillahOm", :description => "Visit http://gigaom.com 5 days a week for two weeks." ).save
  end

  def self.down
    #see migration 186 for notes on why we cant .down gracefully

    #Badge.find_by_name( "KillahOm" ).destroy
  end
end
