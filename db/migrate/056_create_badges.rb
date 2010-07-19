class CreateBadges < ActiveRecord::Migration
  def self.up
    create_table :badges, :id => false do |t|
      t.string :id, :limit => 36
      t.string :name
      t.string :description
      t.string :image
      t.timestamps
    end

    create_table :badges_users, :id => false do |t|
      t.string :badge_id, :limit => 36
      t.string :user_id, :limit => 36
      t.timestamps
    end
    
    add_index :badges, :id
    add_index :badges_users, :badge_id
    add_index :badges_users, :user_id
    
    # Default badges
    Badge.create( :name => "Torch", :description => "For players that visit 100 URLs over a 24 hour period", :image => "/images/badges/default.png" )
    Badge.create( :name => "Indie", :description => "For players who go a 24 hour period without using Google", :image => "/images/badges/default.png" )
    Badge.create( :name => "Bounce Bounce", :description => "For players who read Boing Boing every day they're logged on, for 7 contiguous days", :image => "/images/badges/default.png" )
    Badge.create( :name => "Snowglobe", :description => "For players who visit less than 10 sites in 7 days (but who ARE online during each of those 7 days)", :image => "/images/badges/default.png" )
    Badge.create( :name => "VC", :description => "For players who read Tech Crunch every day they're logged on, for 7 contiguous days", :image => "/images/badges/default.png" )
    Badge.create( :name => "Science, It Works Bitches", :description => "For players who read xkcd.com once a week for 4 contiguous weeks", :image => "/images/badges/default.png" )
    Badge.create( :name => "Achiever", :description => "For players who visit xboxliveachievements.com more than twice a week for 4 contiguous weeks", :image => "/images/badges/default.png" )
    Badge.create( :name => "All About Mii", :description => "For players who visit nintendo.com more than twice a week for 4 contiguous weeks", :image => "/images/badges/default.png" )
  end

  def self.down
    drop_table :badges
    drop_table :badges_users
  end
end