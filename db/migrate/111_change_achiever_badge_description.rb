class ChangeAchieverBadgeDescription < ActiveRecord::Migration
  def self.up
    @achiever_badge = Badge.find( :first, :conditions => { :name => 'Achiever' } )
    @achiever_badge.description = 'For players who visit xboxliveachievements.org and / or live.xbox.com more than twice a week for 4 contiguous weeks'
    @achiever_badge.save 
  end

  def self.down
  end
end
