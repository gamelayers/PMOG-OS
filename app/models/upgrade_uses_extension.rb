# UpgradeUses are also known as Class Points, that is, points the user is rewarded with
# for using the in-game upgrades. In general, they receive class points on interaction for
# mines, crates, st. nicks, portals whilst the remaining upgrades reward the user
# on equipping/deploying (i.e armor, rockets, walls).
module UpgradeUsesExtension
  # Reward a user for using a upgrade. Note that by default a upgrade use is worth
  # 1 point, but we can tweak that for things like mines, we are currently worth
  # half a point, to balance their ease of use
  def reward(upgrade_name, options = {})
    upgrade = Upgrade.cached_single(upgrade_name)
    proxy_owner.user_level.reward_classpoints(upgrade)
    create( :upgrade_id => upgrade.id, :points => upgrade.classpoints)
    expire_memcache(upgrade_name)
  end

  # Returns the upgrade usage count for a single upgrade.
  def filter(upgrade_name, options = {})
    proxy_owner.get_cache("upgrade_uses_filter_#{proxy_owner.id}_#{upgrade_name}") do
      upgrade = Upgrade.cached_single(upgrade_name)
      find( :all, :conditions => { :upgrade_id => upgrade.id } )
    end
  end
  
  # Just a counter
  def uses(upgrade_name, options = {})
    proxy_owner.get_cache("upgrade_uses_count_#{proxy_owner.id}_#{upgrade_name}") do
      upgrade = Upgrade.cached_single(upgrade_name)
      count( :all, :conditions => { :upgrade_id => upgrade.id } )
    end
  end

  protected
  def expire_memcache(upgrade_name, options = {})
    proxy_owner.expire_cache( "upgrade_uses_count_#{proxy_owner.id}_#{upgrade_name}" )
#    proxy_owner.expire_cache( "classpoints_#{proxy_owner.id}" )
  end
end
