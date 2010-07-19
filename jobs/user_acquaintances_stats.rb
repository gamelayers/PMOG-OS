# This will record the current user count and accepted buddies count in a table so we can average them in a graph
#UserAcquaintanceStats.create(:user_count => User.count(:all), :acquaintance_count => Buddy.cached_buddies.size)
