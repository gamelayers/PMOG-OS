namespace :pmog do

  # Run this as rake RAILS_ENV=production pmog:clear_locations
  # Note that the run_test and location counts that wrap the main pruning stuff
  # will probably take a lot longer to run. Be aware :)
  desc "Clear out unused and unwanted locations"
  task( :clear_locations => :environment ) do
    puts "Started at #{Time.now.to_s(:db)}"
    puts "Make sure to DISABLE BJ ON 025 whilst you still can ;-)"

    # Set host and database info from database.yml
    host = `uname -n`.strip rescue nil
    host =~ /^ey*/ ? dump_dir = '/data/dumps' : dump_dir = '/tmp'
    puts "Host set to #{host}, beginning to clear locations..."
    database, user, password, host = retrieve_db_info

    puts "Disabling the web site"
    system( "cp /data/pmog/shared/system/maintenance.html.custom /data/pmog/shared/system/maintenance.html" )

    puts "Dumping the current locations database table to #{dump_dir}/locations.sql"
    system( "/usr/bin/env mysqldump -u#{user} -p#{password} -h#{host} --skip-add-locks --skip-lock-tables --opt #{database} locations > #{dump_dir}/locations.sql" )

    # Notice we don't use a tmp table for the following. If there are any
    # problems we want all the tables to persist
    puts 'Clear out any NULL locations, alert() locations and resetting the locations_tmp table'
    Cron.execute( 'delete from locations where url IS NULL' )
    Cron.execute( 'delete from locations where url LIKE \'%alert(%\'')
    Cron.execute( 'drop table if exists locations_tmp' )
    Cron.execute( 'create table locations_tmp like locations' )

    # Pre-clearing number crunch
    puts "Running some pre-clear-out tests"
    run_tests

    puts 'Select wanted locations into a temporary table'
    # Note that if the locations table starts to grow unwieldy, we can switch daily_domains
    # for badges_locations and keep just the location_ids that are attached to badges, rather than
    # all those attached to daily_domains - duncan 18th September 2008
    [ 'mines', 'portals', 'lightposts', 'branches', 'crates', 'daily_domains', 'portal destinations' ].each do |table|
      puts '...' + table

      table, column, model = set_table_and_column_and_model(table)

      # Gawd, I hope this is fast..
      puts "Starting with the insert.."
      Cron.execute( "insert into locations_tmp(id) select distinct(#{column}) from #{table}" )
    end

    puts "Inserts done, now for the update..."
    Cron.execute( "update locations_tmp, locations set locations_tmp.url = locations.url where locations_tmp.id = locations.id" )
    puts "Update done!"

    # Give MySQL a breather
    puts "Sleep..."
    sleep(300)

    l_rows, l_tmp_rows = count_location_rows
    puts "Selections done. #{l_rows} rows in locations, #{l_tmp_rows} in locations_tmp"

    puts 'Truncate locations'
    Cron.execute( 'truncate locations' )

    puts 'Optimize locations'
    Cron.execute( 'optimize table locations' )

    # This broke on EY, our user doesn't have sufficient privileges
    #puts 'Reload the table'
    #Cron.execute( 'flush table locations' )

    puts "Select wanted locations back into locations"
    Cron.execute( 'insert into locations (id, url, created_at) select distinct(id), url, NOW() from locations_tmp')

    # Give MySQL a breather, again
    puts "Sleep..."
    sleep(300)

    l_rows, l_tmp_rows =count_location_rows
    puts "Selections done again. #{l_rows} rows in locations, #{l_tmp_rows} in locations_tmp"

    puts "Dumping the locations_tmp database table to #{dump_dir}/locations_tmp.sql"
    system( "/usr/bin/env mysqldump -u#{user} -p#{password} -h#{host} --skip-add-locks --skip-lock-tables --opt #{database} locations_tmp > #{dump_dir}/locations_tmp.sql" )

    # Post-clearing number crunch
    puts "Running some post-clear-out tests"
    run_tests

    puts "Enable the web site"
    system( "rm /data/pmog/shared/system/maintenance.html" )

    puts "Don't forget to remove/restore the backup left in #{dump_dir}"

    # Some locations will remain in memcache, though. We might want to clear out
    # all location/branch/etc memcache stores now, but I'm not sure of the best
    # way of doing that, perhaps with a global version key?
    puts "Finished at #{Time.now.to_s(:db)}"
  end

  desc "Grant site admin status to a few users"
  task( :grant_site_admin => :environment ) do
    site_admins = %w{suttree justin merci heavysixer marc octalblack burdenday dutchashell atfriedman}

    site_admins.each do |login|
      admin = User.find_by_login( login ) rescue next

      unless admin.nil? or admin.has_role? 'site_admin'
        # See http://www.writertopia.com/developers/authorization for more information on the authorized plugin
        admin.has_role 'site_admin'
        admin.save
      end
    end
  end

  desc "Convert varchar(36) UUID database ids to int(16) UUID database ids"
  task( :convert_uuids_to_ints => :environment ) do
    puts "About to start converting some 36 char UUIDs to 16 in UUIDs"
    #18:15:06 secondartur: long term, you should consider switching to storing the UUIDs as 16 byte chars
    #18:15:23 secondartur: it makes pretty printing a bitch, but will save you quite a lot over time
    #18:15:26 Duncan Gough: ah ok
    #18:15:40 Duncan Gough: as opposed to 36 chars
    #18:15:58 secondartur: yeah, just pack it into the raw format
    #18:16:04 secondartur: instead of prettyprinted
    #18:16:18 Duncan Gough: how so?
    #18:16:32 secondartur: UUIDs are 128 bit
    #18:16:46 secondartur: but when you print them humand readable, they end up being 36 chars or someting like that
    #18:16:53 secondartur: but you can just store the raw byte value
    #18:17:04 Duncan Gough: oh, i see
    #18:17:54 Duncan Gough: and the raw byte value is still unique?
    #18:17:58 secondartur: yes
    #18:18:00 Duncan Gough: UUID.timestamp_create.to_i vs. UUID.timestamp_create.to_s
    #18:18:08 Duncan Gough: yeah, one is 16, the other is 36
    #18:18:10 Duncan Gough: nice
    #18:18:13 secondartur: yeah
    #18:18:20 secondartur: you can cast the i to the s I am sure
    #18:18:30 Duncan Gough: yeah, just tested and it worked fine
    #18:18:38 Duncan Gough: damn, wish i'd done that earlier :(
    #18:18:57 secondartur: it is easy to do lazy upgrades, check if the string is 36 or 16 bytes :)
    puts "Remeber that if all ids have been converted, change the before_create in config/active_record_extensions.rb"
  end

  desc "Generate code coverage with rcov"
  task :coverage do
    FileUtils.rm_rf "doc/coverage"
    mkdir "doc/coverage"
    rcov = %(rcov --rails --aggregate doc/coverage/coverage.data --text-summary -Ilib --html -o doc/coverage test/**/*_test.rb)
    system rcov
  end

  desc "Generate PMOG Beta login keys - normal users get maximum two a week, the PMOG user gets maximum 100 a week"
  task( :generate_beta_keys => :environment ) do
    User.find(:all).each do |user|
      user.beta_keys.create while user.beta_keys.size < 5
    end

    user = User.find_by_email( 'self@pmog.com' )
    user.beta_keys.create while user.beta_keys.size < 100
  end

  desc "Email PMOG Beta users with keys"
  task( :email_beta_keys => :environment ) do
    BetaUser.find(:all, :conditions => { :emailed => 0, :user_id => PMOG_USER.id }, :limit => 100).each do |u|
      u.email_beta_key
    end
  end

  desc "Setup the newly created branch - usage rake pmog:setup_branch <branchname>"
  task :setup_branch do
    if ARGV[1].nil? or ARGV[1].empty?
      puts 'Usage: rake pmog:setup_branch <branchname>'
    else
      puts 'copying database.yml'
      system "cp #{RAILS_ROOT}/config/database.yml ../branches/#{ARGV[1]}/config/"

      puts 'migrating database'
      system "cd ../branches/#{ARGV[1]}"
      system "rake db:migrate"

      puts 'running tests'
      system( "rake" )
    end
  end

  # This copies the backup dump created by EY to Amazon S3, along with a dump of
  # the image assets and codebase.
  task(:backup_to_s3) do
    require 'yaml'
    require 'rubygems'
    require 'aws/s3'

    app_dir = RAILS_ROOT
    bucket = 'pmog_db_backup'
    backup_name = Date.today.strftime("%Y_%m_%d")
    dump = "/data/pmog/backups/pmog_production_#{backup_name}.dump.gz"

    # The size of our backup dump is larger than is allowed by Amazon, so we first
    # need to split it up into smaller chunks, and upload each one
    puts "Splitting up backup into smaller chunks"
    system( "split -b 1024m #{dump} #{dump}.")
    files = Dir["#{dump}.*"]

    puts "Copying backup from EY offsite"
    files.each do |f|
      AWS::S3::Base.establish_connection!(
        :access_key_id     => '1KZ934ZECJS9M1MGSV82',
        :secret_access_key => 'XXXIGQjcnS8CqFZcluMA2VETj4Wg4iRo57CE3eW7'
      )

      AWS::S3::S3Object.delete(f, bucket) if AWS::S3::S3Object.exists?(f, bucket)
      AWS::S3::S3Object.store(f, open(f), bucket)
    end
    puts "Database transfer complete"

    # And push a backup of the code and image assets too
    code_dump = "/data/pmog/backups/pmog." + `date +%Y-%m-%d`.chomp + ".tar.gz"
    assets_dump = "/data/pmog/backups/pmog_image_assets." + `date +%Y-%m-%d`.chomp + ".tar.gz"

    AWS::S3::S3Object.delete(code_dump, bucket) if AWS::S3::S3Object.exists?(code_dump, bucket)
    AWS::S3::S3Object.store(code_dump, open(code_dump), bucket)
    puts "Code dump and transfer complete"

    AWS::S3::S3Object.delete(assets_dump, bucket) if AWS::S3::S3Object.exists?(assets_dump, bucket)
    AWS::S3::S3Object.store(assets_dump, open(assets_dump), bucket)
    puts "Assets dump and transfer complete"
  end
end

namespace :db do
  desc 'Create YAML test fixtures from data in an existing database.
  Defaults to development database. Set RAILS_ENV to override.'

  task :extract_fixtures => :environment do
    sql = "SELECT * FROM %s"
    skip_tables = ["schema_info", "sessions"]
    ActiveRecord::Base.establish_connection
    tables = ENV['FIXTURES'] ? ENV['FIXTURES'].split(/,/) : ActiveRecord::Base.connection.tables - skip_tables
    tables.each do |table_name|
      i = "000"
      File.open("#{RAILS_ROOT}/db/#{table_name}.yml", 'w') do |file|
        data = ActiveRecord::Base.connection.select_all(sql % table_name)
        file.write data.inject({}) { |hash, record|
          hash["#{table_name}_#{i.succ!}"] = record
          hash
        }.to_yaml
      end
    end
  end
end

namespace :test do
  desc "Copy the test database.yml config file over so the tests can run"
  task(:move_test_db_config) do
    require 'ftools'
    puts "Copying #{RAILS_ROOT}/config/database.yml.test to #{RAILS_ROOT}/config/database.yml"
    File.move(RAILS_ROOT+"/config/database.yml.test", RAILS_ROOT+"/config/database.yml")
  end
end

private
# Load the relevat setings from database.yml
def retrieve_db_info
  # From S3.rake
  result = File.read "#{RAILS_ROOT}/config/database.yml"
  result.strip!
  config_file = YAML::load(ERB.new(result).result)

  return [
    config_file[RAILS_ENV]['database'],
    config_file[RAILS_ENV]['username'],
    config_file[RAILS_ENV]['password'],
    config_file[RAILS_ENV]['host']
  ]
end

# Crunch some numbers on the locations table
def run_tests
  [ 'mines', 'portals', 'lightposts', 'branches', 'crates', 'daily_domains', 'portal destinations' ].each do |table|
    table, column = set_table_and_column_and_model(table)
    location_ids = Cron.find_by_sql( "select count(#{column}) as count from #{table} where #{column} not in (select distinct(id) from locations)" )
    count = location_ids[0].count rescue '0'
    puts "#{count} #{table} #{column}s missing in locations table"
  end
end

# Just a wrapper for handling the fact that portal
# destinations are really locations in disguise. Also returns
# a model derived from table, i.e., passing in 'mines' will return Mine
def set_table_and_column_and_model(table)
  if table == 'portal destinations'
    table = 'portals'
    column = 'destination_id'
  else
    table = table
    column = 'location_id'
  end
  return [table, column, table.classify.constantize]
end

def count_location_rows
  l_count = Cron.find_by_sql( 'select count(*) as count from locations' )
  lt_count = Cron.find_by_sql( 'select count(*) as count from locations_tmp' )
  return [l_count[0].count, lt_count[0].count]
end
