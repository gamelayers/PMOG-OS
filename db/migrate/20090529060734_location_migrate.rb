class LocationMigrate < ActiveRecord::Migration
  CLAZZES = [ Awsmattack, Branch, Crate, [DailyDomain, :get_all_tables], Fave, Giftcard, Lightpost, Mine, Portal, Watchdog ]

  def self.up

        return
 	return if !IsDevelopment

	min_date = OldLocation.minimum(:created_at).yesterday.yesterday # just to be sure
	end_date = Time.now.tomorrow.tomorrow

	puts "#{min_date} => #{end_date}"

	while min_date <= end_date do
  		puts "CURRENT_DATE #{min_date.to_s(:db)}"
		max_date = min_date + 2.hour # do in 2 hour intervals

  		old_locs = OldLocation.find(:all, :conditions => ["created_at >= ? and created_at < ?", min_date, max_date]) 
  		old_locs.each do |old|
    			new_loc = Location.find_or_create_by_url(old.url)
    			#puts "ID: #{new_loc.id}"
    			CLAZZES.each do |clz|
				if clz.class == Array
                                	clz, func = clz
					names = clz.send(func)
					puts "NAMES: #{names}"
				else
					names = [ clz.table_name ]
				end

				names.each { |table_name|
					puts "WORKING ON TABLE #{table_name}"
					clz.set_table_name table_name if clz.table_name != table_name
					execute "update #{table_name} set location_id = '#{new_loc.id}' where old_location_id = '#{old.id}'"
				}
    			end
		end

  		min_date = max_date
	end
  end

  def self.down
  end

end
