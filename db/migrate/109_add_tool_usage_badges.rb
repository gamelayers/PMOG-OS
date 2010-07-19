class AddToolUsageBadges < ActiveRecord::Migration
  def self.up
    Badge.create( :name => "Little Sister", :description => "For players who use more than 250 St. Nicks").save
    Badge.create( :name => "Avenger", :description => "For players who use more than 500 St. Nicks").save
    Badge.create( :name => "Good Doctor", :description => "For players who use more than 1500 St. Nicks").save
    Badge.create( :name => "Normandy", :description => "For players who use more than 250 Mines").save
    Badge.create( :name => "All-Fired", :description => "For players who use more than 500 Mines").save
    Badge.create( :name => "Hell Fire", :description => "For players who use more than 1500 Mines").save
    Badge.create( :name => "Matchstick Girl", :description => "For players who use more than 250 Lightposts").save
    Badge.create( :name => "Illuminati", :description => "For players who use more than 500 Lightposts").save
    Badge.create( :name => "Keeper of the Flame", :description => "For players who use more than 1500 Lightposts").save
    Badge.create( :name => "Invisible Man", :description => "For players who use more than 250 Portals").save
    Badge.create( :name => "Telepmogation", :description => "For players who use more than 500 Portals").save
    Badge.create( :name => "Jaunt", :description => "For players who use more than 1500 Portals").save
    Badge.create( :name => "Trail of Splinters", :description => "For players who use more than 250 Crates").save
    Badge.create( :name => "Biddy", :description => "For players who use more than 500 Crates").save
    Badge.create( :name => "The Giver", :description => "For players who use more than 1500 Crates").save
  end
  
  def self.down
  end
end
