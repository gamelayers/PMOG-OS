# Patching up the indices on daily_domains since we swapped created_at for created_on.
# This migration won't actually run automatically in production, I'm going to do it by hand.
# Since we have so much data in the daily_domains table, we'd be looking at downtime in the order of days
# for this to run. Instead, I'm going to take the slave database offline, run the migration by hand on there,
# put it back online and let it catch up with the missing data. Then I'm going to swap the master with the slave
# and repeate the process, so that both databases are migrated without any downtime.

# Once all that's done, I'll add a row for migration 216 to the schema_migrations table
# and commit this migration to the respitory. That way, our local copies also be in sync with production - duncan 07/08/08

# This takes over a day to run in production. Erik at EngineYard wrote the SQL statments below, after
# running some tests to find the quickest way of doing this. From the original ticket:
# "Actually, I did some testing and I don't the temp table would've been a great idea. 
# There are just over 4.5M rows in the table with created_on < '2008-06-30' and over 17M rows total in the table 
# so that would've taken forever to write. I hadn't actually read through the indexes that were being dropped before 
# to see that there isn't actually an index alread on created_on (which explains my surprise that the DELETE wanted 
# to take so long). So, what I've done is placed the following in a file and run it through mysql in a screen. *Whenever* 
# it's done we can look at doing the failover and then the same on the new replica." - duncan 18/08/08
#
# Note also that when this migration goes out, it will never run in production as I intend to fake an entry
# in schema_migrations so that this query doesn't run. It will only run on our local developer copies.

class DailyDomainIndex < ActiveRecord::Migration
  def self.up
    execute( "ALTER TABLE daily_domains
              DROP INDEX index_daily_domains_on_id,
              DROP INDEX idx_daily_domains_on_user_id_location_id_created_at,
              ADD INDEX idx_daily_domains_on_created_on (created_on)" )

    execute( "DELETE FROM daily_domains WHERE created_on < '#{6.weeks.ago.to_date}'" )

    execute( "ALTER TABLE daily_domains ADD PRIMARY KEY(id),
              ADD INDEX idx_daily_domains_on_location_id(location_id),
              ADD INDEX idx_daily_domains_on_user_id_location_id_created_on (user_id, location_id, created_on)" )

    # Some badges won't work with the user/location/created index, so we have to add another one on user/created/location too
    execute( "ALTER TABLE daily_domains ADD INDEX idx_daily_domains_on_user_id_created_on_location_id (user_id, created_on, location_id)" )

    execute( "OPTIMIZE TABLE daily_domains" )
  end

  def self.down
    # Do the same, but in reverse...
    execute( "ALTER TABLE daily_domains DROP PRIMARY KEY,
              ADD INDEX index_daily_domains_on_id(id),
              DROP INDEX idx_daily_domains_on_created_on,
              DROP INDEX idx_daily_domains_on_location_id,
              DROP INDEX idx_daily_domains_on_user_id_location_id_created_on,
              DROP INDEX idx_daily_domains_on_user_id_created_on_location_id,
              ADD INDEX idx_daily_domains_on_user_id_location_id_created_at(user_id, location_id)" )
    execute( "OPTIMIZE TABLE daily_domains" )
  end
end
