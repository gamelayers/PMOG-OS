class SuspectLimitGameSetting < ActiveRecord::Migration
  def self.up
    GameSetting.create( :key => "Suspect Limit", :value => 15000 )
  end

  def self.down
    GameSetting.find(:all, :conditions => {:key => "Suspect Limit"}).collect{ |g| g.destroy }
  end
end
