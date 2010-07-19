class DefaultDob < ActiveRecord::Migration
  def self.up
    execute( "UPDATE users SET date_of_birth = '1975-02-23' WHERE date_of_birth IS NULL" )
  end

  def self.down
    # No need to migrate down
  end
end
