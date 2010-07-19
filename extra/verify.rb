

#CLAZZES = [ Awsmattack, Branch, Crate, Fave, Giftcard, Lightpost, Mine, Portal, Watchdog ]
CLAZZES = [ Awsmattack, Branch, Crate, DailyDomain, Fave, Giftcard, Lightpost, Mine, Portal, Watchdog ]

CLAZZES.each do |clz|
	puts "WORKING ON #{clz.to_s}"

	items = clz.find(:all, :limit=>10000)


	items.each do |item|	
		puts "Item: #{clz.to_s} #{item.id}"
	
		first  = clz.find(:all, :conditions => ["old_location_id = ?", item.old_location_id])
		second = clz.find(:all, :conditions => ["location_id = ?", item.location_id])
	
		puts first == second
		raise "YIKES, #{clz.to_s}, #{item.to_s}" if first != second
	
	end

end
