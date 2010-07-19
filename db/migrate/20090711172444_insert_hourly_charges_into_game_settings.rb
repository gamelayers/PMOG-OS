class InsertHourlyChargesIntoGameSettings < ActiveRecord::Migration
  def self.up
    bacon_data = {:key => 'Bacon Cost Per Hour', :value => '1'}
    dp_data = {:key => 'DP Cost Per Hour', :value => '10000'}

    bacon_record = GameSetting.find(:first, :conditions => {:key => 'Bacon Cost Per Hour'})
    bacon_record.nil? ? GameSetting.create(bacon_data) : bacon_record.update_attributes(bacon_data)

    dp_record = GameSetting.find(:first, :conditions => {:key => 'DP Cost Per Hour'})
    dp_record.nil? ? GameSetting.create(dp_data) : dp_record.update_attributes(dp_data)
  end

  def self.down
    bacon_record = GameSetting.find(:first, :conditions => {:key => 'Bacon Cost Per Hour'})
    bacon_record.destroy unless bacon_record.nil?

    dp_record= GameSetting.find(:first, :conditions => {:key => 'DP Cost Per Hour'})
    dp_record.destroy unless dp_record.nil?
  end
end
