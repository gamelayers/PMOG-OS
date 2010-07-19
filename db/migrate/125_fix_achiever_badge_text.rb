class FixAchieverBadgeText < ActiveRecord::Migration
  def self.up
    achiever = Badge.find( :first, :conditions => { :name => 'Achiever' } )
    achiever.description = "For players who visit xbox360achievements.org and / or live.xbox.com more than twice a week for 4 contiguous weeks"
    achiever.save
  end

  def self.down
  end
end
