class InsertToolLimitsIntoGameEvents < ActiveRecord::Migration
  def self.up
    grenade_limit_data = { :key => "Max Grenades per Player",
      :value => 5}
    st_nick_limit_data = { :key => "Max St Nicks per Player",
      :value => 5}
    watchdog_limit_data = { :key => "Max Watchdogs per URL",
      :value => 5}

    @grenade_limit = GameSetting.find_by_key('Max Grenades per Player')
    @grenade_limit.nil? ? GameSetting.create(grenade_limit_data) : @grenade_limit.update_attributes(grenade_limit_data)
    @st_nick_limit = GameSetting.find_by_key('Max St Nicks per Player')
    @st_nick_limit.nil? ? GameSetting.create(st_nick_limit_data) : @st_nick_limit.update_attributes(st_nick_limit_data)
    @watchdog_limit = GameSetting.find_by_key('Max Watchdogs per URL')
    @watchdog_limit.nil? ? GameSetting.create(watchdog_limit_data) : @watchdogs_limit.update_attributes(watchdog_limit_data)
  end

  def self.down
  end
end
