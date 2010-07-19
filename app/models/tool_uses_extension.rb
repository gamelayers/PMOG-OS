# ToolUses are also known as Class Points, that is, points the user is rewarded with
# for using the in-game tools. In general, they receive class points on interaction for
# mines, crates, st. nicks, portals whilst the remaining tools reward the user
# on equipping/deploying (i.e armor, rockets, walls).
module ToolUsesExtension
  # Reward a user for using a tool. Note that by default a tool use is worth
  # 1 point, but we can tweak that for things like mines, we are currently worth
  # half a point, to balance their ease of use
  def reward(tool_name, options = {})
    options = { :usage_type => 'tool' }.merge(options)
    tool = Tool.cached_single(tool_name)
    proxy_owner.user_level.reward_classpoints(tool)
    create( :tool_id => tool.id, :points => tool.classpoints, :usage_type => options[:usage_type] )
    expire_memcache(tool_name)
  end

  # Returns the tool usage count for a single tool.
  # We should memoize this, as we do with the inventory tools
  def filter(tool_name, options = {})
    options = { :usage_type => 'tool' }.merge(options)
    proxy_owner.get_cache("tool_uses_filter_#{proxy_owner.id}_#{tool_name}_#{options[:usage_type]}") do
      tool = Tool.cached_single(tool_name)
      find( :all, :conditions => { :tool_id => tool.id, :usage_type => options[:usage_type] } )
    end
  end
  
  # Just a counter
  def uses(tool_name, options = {})
    options = { :usage_type => 'tool' }.merge(options)
    proxy_owner.get_cache("tool_uses_count_#{proxy_owner.id}_#{tool_name}_#{options[:usage_type]}") do
      tool = Tool.cached_single(tool_name)
      count( :all, :conditions => { :tool_id => tool.id, :usage_type => options[:usage_type] } )
    end
  end

  protected
  def expire_memcache(tool_name, options = {})
    options = { :usage_type => 'tool' }.merge(options)
    proxy_owner.expire_cache( "tool_uses_count_#{proxy_owner.id}_#{tool_name}_#{options[:usage_type]}" )
#    proxy_owner.expire_cache( "classpoints_#{proxy_owner.id}" )
  end
end
