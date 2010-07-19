User.all( :conditions => [ "last_login_at > ?", 1.week.ago ] ) do |user|
  user.beta_keys.create while user.beta_keys.count( :conditions => "emailed = 0" ) < 5
end