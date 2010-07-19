class CreateClasspointsForMissions < ActiveRecord::Migration
  def self.up
    mission_pings_data = { :key => "Mission Pings",
      :value => 5}

    @mission_pings = GameSetting.find_by_key('Mission Pings')
    @mission_pings.nil? ? GameSetting.create(mission_pings_data) : @mission_pings.update_attributes(mission_pings_data)

    mission_taken_data = { :name => "A player took your mission",
      :url_name => 'mission_taken',
      :classpoints => 10,
      :short_description => "Pathmakers recieve 10 CP for each player that takes their missions" }

    @mission_taken = MiscAction.find_by_url_name('mission_taken')
    @mission_taken.nil? ? MiscAction.create(mission_taken_data) : @mission_taken.update_attributes(mission_taken_data)
  end

  def self.down
  end
end
