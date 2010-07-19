class AddPingsToMissionTagging < ActiveRecord::Migration
  def self.up
    p = Ping.create(:name => 'mission_tag', :points => 2)
  end

  def self.down
    p = Ping.find_by_name('mission_tag').destroy
  end
end
