class AddPmogMissionFlag < ActiveRecord::Migration
  def self.up
    add_column :missions, :pmog_mission, :boolean, :default => false
  end

  def self.down
    remove_column :missions, :pmog_mission
  end
end
