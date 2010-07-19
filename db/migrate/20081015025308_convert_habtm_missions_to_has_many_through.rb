class ConvertHabtmMissionsToHasManyThrough < ActiveRecord::Migration
  def self.up
    execute "RENAME TABLE missions_users TO missionatings"
  end

  def self.down
    execute "RENAME TABLE missionatings TO missions_users"
  end
end
