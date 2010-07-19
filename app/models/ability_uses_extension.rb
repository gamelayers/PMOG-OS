# AbilityUses are also known as Class Points, that is, points the user is rewarded with
# for using the in-game abilitys. In general, they receive class points on interaction for
# mines, crates, st. nicks, portals whilst the remaining abilitys reward the user
# on equipping/deploying (i.e armor, rockets, walls).
module AbilityUsesExtension
  # Reward a user for using a ability. Note that by default a ability use is worth
  # 1 point, but we can tweak that for things like mines, we are currently worth
  # half a point, to balance their ease of use
  def reward(ability_name, options = {})
    ability = Ability.cached_single(ability_name)
    proxy_owner.user_level.reward_classpoints(ability)
    create( :ability_id => ability.id, :points => ability.classpoints)
    expire_memcache(ability_name)
  end

  # Returns the ability usage count for a single ability.
  def filter(ability_name, options = {})
    proxy_owner.get_cache("ability_uses_filter_#{proxy_owner.id}_#{ability_name}") do
      ability = Ability.cached_single(ability_name)
      find( :all, :conditions => { :ability_id => ability.id } )
    end
  end
  
  # Just a counter
  def uses(ability_name, options = {})
    proxy_owner.get_cache("ability_uses_count_#{proxy_owner.id}_#{ability_name}") do
      ability = Ability.cached_single(ability_name)
      count( :all, :conditions => { :ability_id => ability.id } )
    end
  end

  protected
  def expire_memcache(ability_name, options = {})
    proxy_owner.expire_cache( "ability_uses_count_#{proxy_owner.id}_#{ability_name}" )
#    proxy_owner.expire_cache( "classpoints_#{proxy_owner.id}" )
  end
end
