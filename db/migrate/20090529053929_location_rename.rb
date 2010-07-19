class LocationRename < ActiveRecord::Migration
  CLAZZES = [ Awsmattack, Branch, Crate, [DailyDomain, :get_all_tables], Fave, Giftcard, Lightpost, Mine, Portal, Watchdog ]


  def self.up
    # add missing indexes
    add_index :awsmattacks, :location_id
    add_index :faves, :location_id
    add_index :watchdogs, :location_id

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
          add_column clz.table_name, :location_id, :string, :limit=>40
	}
    end

  end

  def self.down
    remove_index :awsmattacks, :location_id
    remove_index :faves, :location_id
    remove_index :watchdogs, :location_id

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
          remove_column clz.table_name, :location_id
          execute "alter table #{clz.table_name} change column old_location_id location_id varchar(36)"
	}
    end
  end
end
