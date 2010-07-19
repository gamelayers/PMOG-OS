class LocationsUndo < ActiveRecord::Migration
  CLAZZES = [ Awsmattack, Branch, Crate, [DailyDomain, :get_all_tables], Fave, Giftcard, Lightpost, Mine, Portal, Watchdog ]

  def self.up
    puts "ENV: #{ENV['RAILS_ENV']} #{ENV.to_yaml}"
    return 
    return if !IsDevelopment
    puts "DOING IT"

    CLAZZES.each do |clz|
	if clz.class == Array
		clz, func = clz
		names = clz.send(func)
		puts "NAMES: #{names}"
	else
		names = [ clz.table_name ]
	end

	names.each { |table_name|
	  clz.set_table_name table_name if clz.table_name != table_name
          execute "alter table #{clz.table_name} change column location_id new_location_id varchar(36)"
          execute "alter table #{clz.table_name} change column old_location_id location_id varchar(36)"
	  execute "delete from #{clz.table_name} where location_id is NULL"
	}
    end
  end

  def self.down
    return 
    return if !IsDevelopment

    CLAZZES.each do |clz|
	if clz.class == Array
		clz, func = clz
		names = clz.send(func)
		puts "NAMES: #{names}"
	else
		names = [ clz.table_name ]
	end

	names.each { |table_name|
	  clz.set_table_name table_name if clz.table_name != table_name
          execute "alter table #{clz.table_name} change column location_id old_location_id varchar(36)"
          execute "alter table #{clz.table_name} change column new_location_id location_id varchar(36)"
	}
    end
  end

end
