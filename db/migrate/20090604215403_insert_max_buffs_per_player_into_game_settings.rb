class InsertMaxBuffsPerPlayerIntoGameSettings < ActiveRecord::Migration
  def self.up
    overclocks_settings = {:key => 'Max Overclocks Per Player', :value => '25'}
    impedes_settings = {:key => 'Max Impedes Per Player', :value => '25'}

    @max_overclocks = GameSetting.find(:first, :conditions => {:key => 'Max Overclocks Per Player'})
    @max_overclocks.nil? ? GameSetting.create(overclocks_settings) : @max_overclocks.update_attributes(overclocks_settings)

    @max_impedes = GameSetting.find(:first, :conditions => {:key => 'Max Impedes Per Player'})
    @max_impedes.nil? ? GameSetting.create(impedes_settings) : @max_impedes.update_attributes(impedes_settings)
  end

  def self.down
    @max_overclocks = GameSetting.find(:first, :conditions => {:key => 'Max Overclocks Per Player'})
    @max_overclocks.destroy unless @max_overclocks.nil?

    @max_impedes = GameSetting.find(:first, :conditions => {:key => 'Max Impedes Per Player'})
    @max_impedes.destroy unless @max_impedes.nil?
  end
end
