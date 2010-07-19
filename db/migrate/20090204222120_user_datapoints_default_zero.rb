class UserDatapointsDefaultZero < ActiveRecord::Migration
  def self.up
    execute( "alter table users change datapoints datapoints int(7) NOT NULL DEFAULT 0" )
  end

  def self.down
    # No need to migrate down from this
  end
end
