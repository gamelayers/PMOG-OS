# Find 450 of the most recently active people who have checked the 'Periodic Updates' preference
# - return a csv list that can be pasted into Campaign Monitor
#users = User.find_by_sql( "SELECT users.email FROM users, preferences WHERE users.id = preferences.user_id AND preferences.name = 'Periodic Updates on The Nethernet' GROUP BY users.id ORDER BY users.updated_at DESC LIMIT 450" )                                                                                                         
 
# Find everyone who was last active between January 21st and March 2nd 2009
users = User.find_by_sql( "SELECT users.email FROM users, preferences WHERE users.id = preferences.user_id AND preferences.name = 'Periodic Updates on The Nethernet' AND users.updated_at >= '2009-01-21' AND users.updated_at <= '2009-03-02' GROUP BY users.id" )
users.each do |u|
  puts u.email + ','
end
