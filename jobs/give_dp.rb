# dp_per_hour = GameSetting.value("DP Per Hour").to_i
#
# # good enough for now
# User.find(:all, :include => :user_activity, :conditions => "user_activities.activity_at >= DATE_SUB(NOW(), interval 1 hour)").each { |user|
#   puts "PRE: #{user.id} #{user.datapoints}"
#   user.reward_datapoints(user.current_level * (user.admin_or_steward? ? (dp_per_hour * 10) : dp_per_hour))
#   user.save
#   puts "POST: #{user.id} #{user.datapoints}"
# }
