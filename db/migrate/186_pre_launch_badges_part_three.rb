class PreLaunchBadgesPartThree < ActiveRecord::Migration
  def self.up
    group = Group.find_by_name 'URL/Surfing'

    Badge.create( :group_id => group.id, :name => "Crowd Control", :description => "Visit http://massively.com 5 days a week for two weeks. " ).save
    Badge.create( :group_id => group.id, :name => "Lotus Drinkers", :description => "Visit http://valleywag.com 5 days a week for two weeks." ).save
    Badge.create( :group_id => group.id, :name => "Dealers", :description => "Visit http://digg.com 5 days a week for two weeks." ).save
    Badge.create( :group_id => group.id, :name => "Better Than Halo 3", :description => "Visit http://eurogamer.net 5 days a week for two weeks." ).save
    Badge.create( :group_id => group.id, :name => "Queen Bee", :description => "Visit http://perezhilton.com 5 days a week for two weeks." ).save
    Badge.create( :group_id => group.id, :name => "Great Beast", :description => "Visit http://metafilter.com 5 days a week for two weeks." ).save
    Badge.create( :group_id => group.id, :name => "Fun Theory", :description => "Visit http://raphkoster.com 2 days a week for two weeks." ).save
    Badge.create( :group_id => group.id, :name => "Stop Motion", :description => "Visit http://reddit.com 5 days a week for two weeks." ).save
    Badge.create( :group_id => group.id, :name => "Badges. We has them", :description => "Visit http://icanhascheezburger.com 5 days a week for two weeks." ).save
    Badge.create( :group_id => group.id, :name => "Champion", :description => "Visit http://change-congress.org 3 days a week for two weeks." ).save
    Badge.create( :group_id => group.id, :name => "Web of Warcraft", :description => "Visit http://worldofwarcraft.com, http://thottbot.com, or http://wowinsider.com 3 days a week for two weeks." ).save
  end

  def self.down

    #Our updates to the badge object itself prevent us from dropping this data gracefully
    #if you descend from HEAD then this entire table will be dropped by the time we make it this far down, anyway
    #if you aren't descending from HEAD then this change shouldn't be committed and the old self.down will still function


    #Badge.find_by_name( "Crowd Control" ).destroy
    #Badge.find_by_name( "Lotus Drinkers" ).destroy
    #Badge.find_by_name( "Dealers" ).destroy
    #Badge.find_by_name( "Better Than Halo 3" ).destroy
    #Badge.find_by_name( "Queen Bee" ).destroy
    #Badge.find_by_name( "Great Beast" ).destroy
    #Badge.find_by_name( "Fun Theory" ).destroy
    #Badge.find_by_name( "Stop Motion" ).destroy
    #Badge.find_by_name( "Badges. We has them" ).destroy
    #Badge.find_by_name( "Champion" ).destroy
    #Badge.find_by_name( "Web of Warcraft" ).destroy
  end
end
