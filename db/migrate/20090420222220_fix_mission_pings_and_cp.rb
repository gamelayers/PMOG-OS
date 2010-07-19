class FixMissionPingsAndCp < ActiveRecord::Migration
  def self.up
    Mission.all do |mission|
      if mission.is_active
        mission.user.user_level.pathmaker_cp += 100
        mission.user.user_level.save
      end
    end

    @mission_published_data = Hash[:name => "Mission Published",
      :url_name => "mission_published",
      :classpoints => 150,
      :pmog_class_id => PmogClass.find_by_name("Pathmakers").id]

    @mission_published = MiscAction.find_by_url_name('mission_published')
    @mission_published.nil? ? MiscAction.create(@mission_published_data) : @mission_published.update_attributes(@mission_published_data)

    @portal_transportation = MiscAction.find_by_url_name('portal_transportation')
    @portal_transportation.update_attributes(:classpoints => 2)

    Ping.create(:name => 'Mission Taken', :points => 10)

    @mission_pings = GameSetting.find_by_key('Mission Pings')
    @mission_pings.destroy
  end

  def self.down
    Mission.all do |mission|
      if mission.is_active
        mission.user.user_level.pathmaker_cp -= 100
        mission.user.user_level.save
      end
    end

    @taken_pings = Ping.find_by_name('Mission Taken')
    @taken_pings.destroy

    GameSetting.create(:key => 'Mission Pings', :value => 10)

    @mission_published = MiscAction.find_by_url_name('mission_published')
    @mission_published.destroy
  end
end
