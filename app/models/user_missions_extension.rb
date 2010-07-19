module UserMissionsExtension
  # Returns all the missions this user has completed
  def completed(sort = 'missions.created_at DESC')
    Mission.find( :all, :conditions => [ 'missionatings.user_id = ?', proxy_owner.id ], :order => sort, :include => :users )
  end
  
  # Return just a count of the missions this user has completed.
  # Uses find_by_sql as this is faster than a Mission.count with :include => :users
  def count_completed
    proxy_owner.get_cache('count_completed') do
      Mission.find_by_sql( [ 'select count(mission_id) as count_all from missionatings where user_id = ?', proxy_owner.id ] )[0].count_all.to_i
    end
  end
  
  def count_drafts
    proxy_owner.get_cache('count_created') do
      Mission.count_with_inactive( :all, :conditions => [ 'missions.user_id = ? and is_active = ?', proxy_owner.id, 0 ] )
    end
  end
  
  # Return just a count of the missions this user has created
  def count_created
    proxy_owner.get_cache('count_created') do
      Mission.count( :all, :conditions => [ 'missions.user_id = ?', proxy_owner.id ] )
    end
  end
  
  def total_mission_takers
    count = 0
    @missions = Mission.find_all_by_user_id(proxy_owner.id)
    @missions.each do |m|
      count += m.users.size
    end
    return count
  end
  
  def acquaintances_latest_missions(limit = 20, sort='missions.created_at DESC')
    proxy_owner.get_cache('acquaintances_latest_missions', :ttl => 2.days) do
      missions = Mission.find_by_sql( [ 'SELECT missions.*, users.* 
                                         FROM missions, users 
                                         WHERE missions.user_id = users.id 
                                         AND missions.user_id IN (?) 
                                         GROUP BY missions.id 
                                         ORDER BY ?
                                         LIMIT ?', proxy_owner.buddy_ids.uniq[0..99], sort, limit ] )
      missions.collect{ |m| m.user.assets } # pre-load the user and assets so they are cached
      missions
    end
  end
end
