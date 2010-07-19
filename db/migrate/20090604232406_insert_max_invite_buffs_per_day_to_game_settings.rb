class InsertMaxInviteBuffsPerDayToGameSettings < ActiveRecord::Migration
  def self.up
    AbilityStatus.update_all("daily_invite_buffs='5'")

    daily_settings = {:key => 'Max Daily Buffs Castable', :value => '5'}

    @dailies = GameSetting.find(:first, :conditions => {:key => 'Max Daily Buffs Castable'})
    @dailies.nil? ? GameSetting.create(daily_settings) : @dailies.update_attributes(daily_settings)
  end

  def self.down
    @dailies = GameSetting.find(:first, :conditions => {:key => 'Max Daily Buffs Castable'})
    @dailies.destroy unless @dailies.nil?
  end
end
