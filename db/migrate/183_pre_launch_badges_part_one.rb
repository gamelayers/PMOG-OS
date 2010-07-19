class PreLaunchBadgesPartOne < ActiveRecord::Migration
  def self.up
    add_column :badges, :url_name, :string, :limit => 255, :null => false
    Badge.reset_column_information

    group = Group.find_by_name 'URL/Surfing'

    Badge.create( :name => "Dorian's Darlings", :group_id => group.id, :description => "4 facebook.com urls a day four days out of every seven, four weeks in a row." )
    Badge.create( :name => "Space is the Place", :group_id => group.id,  :description => "3 myspace.com urls a day, four days out of every seven, four weeks in a row." )
    Badge.create( :name => "Mesmerized", :group_id => group.id,  :description => "4 youtube.com urls a day, three days each week, four weeks in a row." )
    Badge.create( :name => "Soul Catcher", :group_id => group.id,  :description => "4 hits at Flickr.com a day, four days a week, four weeks in a row." )
    Badge.create( :name => "Take Me to Your Readers", :group_id => group.id,  :description => "Visit io9.com three times a week for a month." )
    Badge.create( :name => "Little Birdie", :group_id => group.id,  :description => "Visit twitter.com once a week for a month." )
    Badge.create( :name => "The Red Tent", :group_id => group.id,  :description => "Visit jezebel.com on three days of the week for a month." )
    Badge.create( :name => "Flying with Radar", :group_id => group.id,  :description => "Visit dopplr.com once a week for a month." )
    Badge.create( :name => "Awrooo!", :group_id => group.id,  :description => "Visit oreilly.com once a week for a month." )
    Badge.create( :name => "Thumb Buster", :group_id => group.id,  :description => "Visit any of kotaku.com, joystiq.com, eurogamer.com or gamespot.com once a week for a month." )

    Badge.find(:all).each do |badge|
      badge.url_name = badge.create_permalink(badge.name)
      badge.save
    end
  end

  def self.down
    # see migration 186 for notes on why we cant .down gracefully

#    Badge.find_by_name( "Dorian's Darlings" ).destroy
#    Badge.find_by_name( "Space is the Place" ).destroy
#    Badge.find_by_name( "Mesmerized" ).destroy
#    Badge.find_by_name( "Soul Catcher" ).destroy
#    Badge.find_by_name( "Take Me to Your Readers" ).destroy
#    Badge.find_by_name( "Little Birdie" ).destroy
#    Badge.find_by_name( "The Red Tent" ).destroy
#    Badge.find_by_name( "Flying with Radar" ).destroy
#    Badge.find_by_name( "Awrooo!" ).destroy
#    Badge.find_by_name( "Thumb Buster" ).destroy
    
    remove_column :badges, :url_name
  end
end
