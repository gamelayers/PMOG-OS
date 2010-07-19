# Trim down daily_domains to just the last 4 weeks of data by creating a tmp/archive 
# table and swapping that with the original one. Run this to get the daily_domains
# table under control, and run jobs/archive_daily_domains.rb to split up the archive
# table in smaller, date-stamped tables.

puts "Started at #{Time.now.to_s(:db)}"
puts "Rotating daily_domains table"
puts "Make sure to disable the website with 'cap production deploy:web:disable'"

puts "Starting in 60 seconds!"
sleep(60)
puts "Starting..."

begin
  DailyDomain.execute( "CREATE TABLE daily_domains_tmp LIKE daily_domains" )
  DailyDomain.execute( "INSERT INTO daily_domains_tmp SELECT * FROM daily_domains WHERE created_on >= '#{4.weeks.ago.at_beginning_of_month.to_s(:db)}'" )
  DailyDomain.execute( "RENAME TABLE daily_domains TO daily_domains_archive" )
  DailyDomain.execute( "RENAME TABLE daily_domains_tmp TO daily_domains" )
  DailyDomain.execute( "DELETE FROM daily_domains_archive where created_on >= '#{4.weeks.ago.at_beginning_of_month.to_s(:db)}'" )
rescue Exception => e
  puts "Caught exception => #{e.message}"
end

puts "Make sure to enable the website with 'cap production deploy:web:enable'"
puts "And now run jobs/archive_daily_domains.rb to process the daily_domains_archive table"
puts "Finished at #{Time.now.to_s(:db)}"