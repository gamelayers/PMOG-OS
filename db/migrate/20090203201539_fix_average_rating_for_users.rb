class FixAverageRatingForUsers < ActiveRecord::Migration
  def self.up
    # Oops, tinyint(1) and int(1) is used for boolean in Rails..
    execute( "alter table users change average_rating average_rating int(2) NOT NULL default 0" )
  end

  def self.down
    execute( "alter table users change average_rating average_rating tinyint(1) NOT NULL default 0" )
  end
end
