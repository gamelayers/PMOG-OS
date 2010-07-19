class UserLightpostsIndex < ActiveRecord::Migration
  def self.up
    execute( "CREATE INDEX idx_user_id_updated_at ON lightposts(user_id, updated_at)" )
  end

  def self.down
    execute( "ALTER TABLE lightposts DROP INDEX idx_user_id_updated_at" )
  end
end
