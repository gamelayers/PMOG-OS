# Process the daily_domains_archive table into smaller tables, re-index the archive tables
# and denormalising the data so that we can trim the locations table too. Run this multiple 
# times by hand until the daily_domains_archive table is empty.

puts "Started at #{Time.now.to_s(:db)}"

# Find the oldest date in the daily_domains_archive table
oldest = DailyDomain.find(:first, :from => 'daily_domains_archive', :select => 'month, year, created_on', :order => 'created_on ASC')

if oldest.nil?
  puts "No data found to archive."
else
  beginning = "#{oldest.created_on.strftime('%Y-%m')}-01"
  ending = "#{oldest.created_on.strftime('%Y-%m')}-31"
  month_year = oldest.created_on.strftime('%m_%y')
  puts "Processesing #{month_year}"

  # Create an archived table of domains for that year and month.
  # Note that the indexes aren't copied across, but that will also save us disk space too
  begin
    puts "Archiving domains from #{beginning} to #{ending}"
    DailyDomain.execute( "CREATE TABLE daily_domains_#{month_year} AS SELECT * FROM daily_domains_archive WHERE created_on >= '#{beginning}' AND created_on <= '#{ending}'" )

    # Also, we don't want to keep the locations table full of records that are only used in these archive tables,
    # so let's copy over the relevant location urls so that we can drop the related locations records if we wish
    puts "Rows copied, denormalising archive table"
    DailyDomain.execute( "ALTER TABLE daily_domains_#{month_year} ADD url varchar(255)" )
    DailyDomain.execute( "UPDATE daily_domains_#{month_year}, locations SET daily_domains_#{month_year}.url = locations.url WHERE daily_domains_#{month_year}.location_id = locations.id" )
  rescue Exception => e
    # Since this could be a serious problem, a trustee should be informed!
    options = {
      :title => "Archive Daily Domains Error!", 
      :body => "There was a problem archiving the daily domains table via a background job (./jobs/archive_daily_domains.rb)\n\nThe error message was #{e.message}",
      :recipient => User.find_by_login('suttree'),
    }
    Message.send_pmog_message(options)

    puts "Caught exception => #{e.message}"
    exit
  end
  puts "Daily domains archived for #{month_year}"
end

puts "Now you can check and drop daily_domains_tmp and daily_domains_archive if they still exist"
puts "Finished at #{Time.now.to_s(:db)}"