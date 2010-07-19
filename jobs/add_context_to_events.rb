# Moved from the migration (db/migrate/0081029145027_add_context_to_events.rb)
# since it takes too long to run on production - duncan 30/10/08

# Add the context to the correct record by scanning the message content
Event.all(:conditions => 'context IS NULL') do |event|
  case event.message
  when /unlocked the/i
   event.update_attribute(:context, "badge_unlocked")

  when /commented on/i
   event.update_attribute(:context, "comment_created")

  when /became rivals with/i
   event.update_attribute(:context, "connection_approved")

  when /allied with/i
   event.update_attribute(:context, "connection_approved")

  when /became acquainted with/i
   event.update_attribute(:context, "connection_approved")
 
  when /ended a rivalry/i
   event.update_attribute(:context, "connection_removed")
 
  when /cancelled an alliance/i
   event.update_attribute(:context, "connection_removed")
 
  when /cancelled an acquaintance/i
   event.update_attribute(:context, "connection_removed")
 
  when /looted (.+)'s crate/i
   event.update_attribute(:context, "crate_looted")

  when /stashed a crate/i
   event.update_attribute(:context, "crate_stashed")
 
  when /statshed a crate/i
   event.update_attribute(:context, "crate_stashed")

  when /just laid a crate/i
   event.update_attribute(:context, "crate_stashed")
 
  when /posted in (.+) in the Forums/i
   event.update_attribute(:context, "forum_post_created")

  when /created a new forum topic/i
   event.update_attribute(:context, "forum_topic_created")

  when /foiled (.+) mine with armor/i
   event.update_attribute(:context, "mine_deflected")

  when /deployed a mine on/i
   event.update_attribute(:context, "mine_deployed")
 
  when /tripped (.+) mine/i
   event.update_attribute(:context, "mine_tripped")
 
  when /completed a mission/i
   event.update_attribute(:context, "mission_completed")
 
  when /made a mission/i
   event.update_attribute(:context, "mission_published")      
 
  when /published a mission called/i
   event.update_attribute(:context, "mission_published")      
 
  when /opened up a Portal/i
   event.update_attribute(:context, "portal_deployed")

  when /teleported by (.+) portal/i
   event.update_attribute(:context, "portal_used")

  when /updated their profile/i
   event.update_attribute(:context, "profile_updated")

  when /foiled (.+) attempt to deploy a mine/i
   event.update_attribute(:context, "st_nick_activated")

  when /got a promotion to Steward from/i
   event.update_attribute(:context, "steward_created")

  when /signed up!/i
   event.update_attribute(:context, "user_created")

  when /reached level/i
   event.update_attribute(:context, "user_leveled")

  when /pardoned from being suspended!/i
   event.update_attribute(:context, "user_pardoned")

  when /suspended for/i
   event.update_attribute(:context, "user_suspended")

  when /just created a new forum post/
   event.update_attribute(:context, "forum_post_created")

  when /just cancelled a rivalry with/i
   event.update_attribute(:context, "connection_removed")

  when /just cancelled a acquaintance with/i
   event.update_attribute(:context, "connection_approved")

  when /just came back/
   next
 
  when /just logged in/i
   next
  else
    puts "could not update this event: #{event.id}"
    puts "message: #{event.message}"
  end
end
