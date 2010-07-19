# We could use 1.week.ago here, but I'm bringing it down to only Users who
# have logged in, in the last 2 days, since Badges are running slow - duncan 24/02/09
User.all( :conditions => [ "last_login_at > ?", 5.days.ago ] ) do |user|
  Badge.grant_all_to user
end
