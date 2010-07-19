class AddArmorBadges < ActiveRecord::Migration
  def self.up
    Badge.create( :name => "Shields Up", :description => "For players who use more than 250 pieces of Armor").save
    Badge.create( :name => "Beatenest", :description => "For players who use more than 500 pieces of Armor").save
    Badge.create( :name => "Tank", :description => "For players who use more than 1500 pieces of Armor").save
  end

  def self.down
  end
end
