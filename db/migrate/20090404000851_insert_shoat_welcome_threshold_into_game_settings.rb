class InsertShoatWelcomeThresholdIntoGameSettings < ActiveRecord::Migration
  def self.up
    welcome_dp_data = { :key => "Shoat Welcome DP Threshold",
      :value => 200}

    @welcome_dp = GameSetting.find_by_key('Shoat Welcome DP Threshold')
    @welcome_dp.nil? ? GameSetting.create(welcome_dp_data) : @welcome_dp.update_attributes(welcome_dp_data)
  end

  def self.down
  end
end
