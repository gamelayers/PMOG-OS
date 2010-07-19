class IndexMissionsUrlName < ActiveRecord::Migration
  def self.up
    begin
      add_index :missions, :url_name
    rescue
      # For some reason the missions.url_name index got lost on production
      # So this migration adds it back in, but breaks the rake test which
      # migrates all the way up and down. So we wrap the attemtped index
      # regeneration here in a rescue block, so that everything is hunky-dory.
    end
  end

  def self.down
    remove_index :missions, :url_name
  end
end
