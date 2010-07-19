class DailyClasspoints < ActiveRecord::Base
  
  set_table_name 'daily_classpoints'

  acts_as_cached
	
  belongs_to :user

  def self.random_leader pmog_class_id
    leaders_for(pmog_class_id).rand.user
  end

  # Find the leaderboards for the supplied class ID for yesterday.
  def self.leaders_for pmog_class_id, limit = 10
    get_cache("#{pmog_class_id}_#{limit}_#{Date.today.to_s(:db)}", :ttl => 1.day) do
      npc_role = Role.find_by_name('npc')
      trustee_role = Role.find_by_name('site_admin')
      find(:all, :include => :user, :conditions => ["daily_classpoints.pmog_class_id = ? AND daily_classpoints.created_at BETWEEN ? AND ? AND users.id NOT IN (SELECT user_id FROM roles_users WHERE user_id = users.id AND role_id = #{npc_role.id} OR role_id = #{trustee_role.id})", pmog_class_id, Date.yesterday.at_beginning_of_day.getutc.to_s(:db), Date.yesterday.end_of_day.getutc.to_s(:db)], :order => "points DESC", :limit => limit)
    end
  end

  def self.total_for user_id, pmog_class_id
    find(:first, :conditions => ["pmog_class_id = ? AND user_id = ? AND created_at BETWEEN ? AND ?", pmog_class_id, user_id, Date.yesterday.at_beginning_of_day.getutc.to_s(:db), Date.yesterday.end_of_day.getutc.to_s(:db)])
  end

  # Increment the players earned classpoints for todays date.
  def self.update_total_by user_id, pmog_class_id, points
    # grab today's record if it 
    record = find(:first, :conditions => ["daily_classpoints.user_id = ? AND daily_classpoints.pmog_class_id = ? AND daily_classpoints.created_at BETWEEN ? AND ?", user_id, pmog_class_id, Date.today.at_beginning_of_day.getutc.to_s(:db), Date.today.end_of_day.getutc.to_s(:db)])
    data = {:user_id => user_id, :pmog_class_id => pmog_class_id, :points => points}

    if record.nil?
      # make a new one if its the first time today
      create(data)
    else
      # merge w/ the old record
      data[:points] = data[:points] + record[:points]
      record.update_attributes(data)
    end
  end

  def self.generate_todays_events
    role = Role.find_by_name('npc')
    PmogClass.all do |pmog_class|
      @leaders = find(:all, :include => :user, :conditions => ["daily_classpoints.pmog_class_id = ? AND daily_classpoints.created_at BETWEEN ? AND ? AND users.id NOT IN (SELECT user_id FROM roles_users WHERE user_id = users.id AND role_id = #{role.id})", pmog_class.id, Date.yesterday.at_beginning_of_day.getutc.to_s(:db), Date.yesterday.end_of_day.getutc.to_s(:db)], :order => "points DESC", :limit => 10)

      @leaders.each_with_index do |leader_data, i|
        Event.record :context => "#{pmog_class.name.singularize.downcase}_leaderboard",
          :user_id =>leader_data.user_id,
          :recipient_id => leader_data.user_id,
          :message => "placed #{(i+1).ordinalize} on the <a href=\"#{leader_data.pmog_host}/leaderboard/classes/#{pmog_class.name}\">#{pmog_class.name} Leaderboard</a> for #{Date.yesterday.to_s}"

      end
    end
  end

end
