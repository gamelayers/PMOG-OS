# MiscActionUses are also known as Class Points, that is, points the user is rewarded with
# for using the in-game misc_actions. In general, they receive class points on interaction for
# mines, crates, st. nicks, portals whilst the remaining misc_actions reward the user
# on equipping/deploying (i.e armor, rockets, walls).
module MiscActionUsesExtension
  # Reward a user for using a misc_action. Note that by default a misc_action use is worth
  # 1 point, but we can tweak that for things like mines, we are currently worth
  # half a point, to balance their ease of use
  def reward(misc_action_name, options = {})
    misc_action = MiscAction.cached_single(misc_action_name)
    proxy_owner.user_level.reward_classpoints(misc_action)
    create( :misc_action_id => misc_action.id, :points => misc_action.classpoints)
    expire_memcache(misc_action_name)
  end

  # Returns the misc_action usage count for a single misc_action.
  def filter(misc_action_name, options = {})
    proxy_owner.get_cache("misc_action_uses_filter_#{proxy_owner.id}_#{misc_action_name}") do
      misc_action = MiscAction.cached_single(misc_action_name)
      find( :all, :conditions => { :misc_action_id => misc_action.id } )
    end
  end
  
  # Just a counter
  def uses(misc_action_name, options = {})
    proxy_owner.get_cache("misc_action_uses_count_#{proxy_owner.id}_#{misc_action_name}") do
      misc_action = MiscAction.cached_single(misc_action_name)
      count( :all, :conditions => { :misc_action_id => misc_action.id } )
    end
  end

  protected
  def expire_memcache(misc_action_name, options = {})
    proxy_owner.expire_cache( "misc_action_uses_count_#{proxy_owner.id}_#{misc_action_name}" )
#    proxy_owner.expire_cache( "classpoints_#{proxy_owner.id}" )
  end
end
