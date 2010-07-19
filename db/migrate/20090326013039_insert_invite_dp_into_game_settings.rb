class InsertInviteDpIntoGameSettings < ActiveRecord::Migration
  def self.up
    invite_dp_data = { :key => "Invite DP",
      :value => 200}
    invite_pings_data = { :key => "Invite Pings",
      :value => 50}

    @invite_dp = GameSetting.find_by_key('Invite DP')
    @invite_dp.nil? ? GameSetting.create(invite_dp_data) : @invite_dp.update_attributes(invite_dp_data)
    @invite_pings = GameSetting.find_by_key('Invite Pings')
    @invite_pings.nil? ? GameSetting.create(invite_pings_data) : @invite_pings.update_attributes(invite_pings_data)
  end

  def self.down
  end
end
