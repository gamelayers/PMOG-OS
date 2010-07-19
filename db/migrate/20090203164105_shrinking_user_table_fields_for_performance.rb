class ShrinkingUserTableFieldsForPerformance < ActiveRecord::Migration
  def self.up
    # These fields see a lot of updates, remember_token especially, so shrinking the size
    # of the field in the database should speed things up.
    execute( "alter table users change login login varchar(20)" )
    execute( "alter table users change email email varchar(40)" )
    execute( "alter table users change remember_token remember_token varchar(40)" )
    execute( "alter table users change datapoints datapoints int(7)" )
    execute( "alter table users change available_pings available_pings int(7) NOT NULL default 0" )
    execute( "alter table users change failed_login_attempts failed_login_attempts int(2) NOT NULL default 0" )
    execute( "alter table users change average_rating average_rating tinyint(1) NOT NULL default 0" )
    execute( "alter table users change total_ratings total_ratings int(5) NOT NULL default 0" )
    execute( "alter table users change ratings_count ratings_count int(5) NOT NULL default 0" )
  end

  def self.down
    execute( "alter table users change login login varchar(255)" )
    execute( "alter table users change email email varchar(255)" )
    execute( "alter table users change remember_token remember_token varchar(255)" )
    execute( "alter table users change datapoints datapoints int(11) NOT NULL default 0" )
    execute( "alter table users change available_pings available_pings int(11) NOT NULL default 0" )
    execute( "alter table users change failed_login_attempts failed_login_attempts int(11) NOT NULL default 0" )
    execute( "alter table users change average_rating average_rating int(11) NOT NULL default 0" )
    execute( "alter table users change total_ratings total_ratings int(11) NOT NULL default 0" )
    execute( "alter table users change ratings_count ratings_count int(11) NOT NULL default 0" )
  end
end
