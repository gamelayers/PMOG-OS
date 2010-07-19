# Everyone who signed up to play PMOG before we became TheNethernet gets a badge
badge = Badge.find_by_name('PMOG')
User.all( :conditions => [ "created_at < '2009-03-01 23:59:59'" ] ) do |user|
  user.badges << badge unless user.badges.include? badge
end
