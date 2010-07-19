class AddInitialActions < ActiveRecord::Migration
  def self.up
    Action.create(:name => "Loot a crate", :context => "receive")
    Action.create(:name => "Trip a mine", :context => "receive")
    Action.create(:name => "Activate a St. Nick", :context => "receive")
    Action.create(:name => "Take a mission", :context => "receive")
    Action.create(:name => "Take a portal", :context => "receive")
    
    Action.create(:name =>"Leave a crate", :context => "perform")
    Action.create(:name =>"Leave a mine", :context => "perform")
    Action.create(:name =>"St. Nick a player", :context => "perform")
    Action.create(:name =>"Leave a lightpost", :context => "perform")
    Action.create(:name =>"Make a mission", :context => "perform")
    Action.create(:name =>"Leave a portal", :context => "perform")
    Action.create(:name =>"Don armor", :context => "perform")
    Action.create(:name =>"Send a message", :context => "perform")
    Action.create(:name =>"Unlock a badge", :context => "perform")
    Action.create(:name =>"Make an acquaintance", :context => "perform")
    Action.create(:name =>"Make a rival", :context => "perform")
    Action.create(:name =>"Make an ally", :context => "perform")
  end

  def self.down
    Action.destroy_all
  end
end
