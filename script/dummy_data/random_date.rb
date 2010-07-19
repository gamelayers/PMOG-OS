class RandomDate
	# From http://snipplr.com/view/3393/random-date/
	
	# generates a random date
	# you can simply call it like random_date to generate a simple random date
	# otherwise you can pass hash values to generate like
	#       random_date :year => your_year, :month => range_of_month, 
	#                   :day => range_of_days, :format => format_string (same as Date#strftime)
	#                   :return_date => true/false (will return a date object if true)
	def self.random_date(options={})
	  options[:year] ||= Time.now.year
	  options[:month] ||= rand(12)
	  options[:day] ||= rand(31)
	  options[:format] ||= "%Y-%m-%d"
	  options[:return_date] ||= false
  
	  str = "#{options[:year]}-#{options[:month]}-#{options[:day]}".to_date.strftime options[:format]
	  date = "#{options[:year]}-#{options[:month]}-#{options[:day]}".to_date
  
	  options[:return_date] ? date : str
	# if the date is invalid let's re-try we'll probably get a valid date the next time around
	# we're passing format because the format needs to stay consistent  
	rescue ArgumentError
	  random_date :format => options[:format]
	end
end