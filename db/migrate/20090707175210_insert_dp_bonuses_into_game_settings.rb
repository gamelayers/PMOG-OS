class InsertDpBonusesIntoGameSettings < ActiveRecord::Migration
  def self.up
    mission_dp = {:key => 'DP Per Mission', :value => '10'}
    portal_dp = {:key => 'DP Per Portal', :value => '25'}
    hourly_dp = {:key => 'DP Per Hour', :value => '25'}

    @mission_dp = GameSetting.find(:first, :conditions => {:key => 'DP Per Mission'})
    @mission_dp.nil? ? GameSetting.create(mission_dp) : @mission_dp.update_attributes(mission_dp)

    @portal_dp = GameSetting.find(:first, :conditions => {:key => 'DP Per Portal'})
    @portal_dp.nil? ? GameSetting.create(portal_dp) : @mission_dp.update_attributes(portal_dp)

    @hourly_dp = GameSetting.find(:first, :conditions => {:key => 'DP Per Hour'})
    @hourly_dp.nil? ? GameSetting.create(hourly_dp) : @mission_dp.update_attributes(hourly_dp)
  end

  def self.down
    @mission_dp = GameSetting.find(:first, :conditions => {:key => 'DP Per Mission'})
    @mission_dp.destroy unless @mission_dp.nil?
    @portal_dp = GameSetting.find(:first, :conditions => {:key => 'DP Per Portal'})
    @portal_dp.destroy unless @portal_dp.nil?
    @hourly_dp = GameSetting.find(:first, :conditions => {:key => 'DP Per Hour'})
    @hourly_dp.destroy unless @hourly_dp.nil?
  end
end
