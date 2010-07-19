# DismissableExtension is currently used to permanently dismiss
# overlays for Missions, Branches and Portals
module DismissableExtension
  # Dismiss this event
  def dismiss(user)
    create( :user_id => user.id )
    expire_cache("exists_#{proxy_owner.id}_#{user.id}")
  end
  
  # Has the user dismissed this event?
  def dismissed_by?(user)
    get_cache( "exists_#{proxy_owner.id}_#{user.id}", :ttl => 1.week ) do
      exists?( :user_id => user.id )
    end
  end
end
