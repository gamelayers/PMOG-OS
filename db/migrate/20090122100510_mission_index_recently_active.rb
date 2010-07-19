class MissionIndexRecentlyActive < ActiveRecord::Migration
  def self.up
    execute( "CREATE INDEX idx_recently_active ON missions(nsfw, average_rating, is_active, created_at)" )
  end

  def self.down
    execute( "ALTER TABLE missions DROP INDEX idx_recently_active" )
  end
end
