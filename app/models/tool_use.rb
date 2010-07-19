# == Schema Information
# Schema version: 20081220201004
#
# Table name: tool_uses
#
#  id         :string(36)    default(""), not null, primary key
#  tool_id    :string(36)    
#  user_id    :string(36)    
#  created_at :datetime      
#  updated_at :datetime      
#  points     :float         not null
#  usage_type :string(255)   default("tool")
#

# Laying a mine, deploying a portal, firing a rocket - all these things are temporary actions
# that have a permanent effect on your PMOG profile. The ToolUse class keeps track of these things,
# so that we can infer your game class from your active actions.
class ToolUse < ActiveRecord::Base
  acts_as_cached

  belongs_to :tool
  belongs_to :user

  validates_presence_of :tool_id, :user_id
  
  # How many of tool x were used, or how many of tool x did user y use?
  # THIS IS DISBALED FOR NOW, SINCE IT KILLS MYSQL, EVEN WHEN USING AN INDEX - duncan 13/02/09
  def self.total(tool, user = nil, usage_type = 'tool')
    0
    #get_cache( "tool_use_total_#{tool}_#{user}_#{usage_type}", :ttl => 1.day ) {
    #  ToolUse.slave_setup do
    #    if user
    #      count( :conditions => { :tool_id => tool.id, :user_id => user.id, :usage_type => usage_type } )
    #    else
    #      count( :conditions => { :tool_id => tool.id, :usage_type => usage_type } )
    #    end
    #  end
    #}
  end

  # Note that we don't use a 'tool_id IN (?)' query here as that results
  # in a filesort, so we run a series of individual counts and increment the counts
  def self.order_counts
    get_cache('order_point_count', :ttl => 2.days) do
      # First we need to grab the IDs of the various tools in the Order side.
      # We do this to avoid the possiblity of stale data.
      ToolUse.slave_setup do
        crate_id = Tool.cached_single('crates').id
        lightpost_id = Tool.cached_single('lightposts').id
        armor_id = Tool.cached_single('armor').id
        
        counts = OpenStruct.new
        counts.daily = counts.weekly = counts.monthly = counts.overall = 0
        [crate_id, lightpost_id,armor_id].each do |tool_id|
          # Using USE INDEX to make sure the right index is used
          counts.daily += ToolUse.find_by_sql( [ "SELECT count(id) AS count FROM tool_uses USE INDEX (index_tool_uses_on_tool_id_and_created_at) WHERE tool_id = ? AND created_at >= ?", tool_id, 1.day.ago ] )[0].count.to_i rescue 0
          counts.weekly += ToolUse.find_by_sql( [ "SELECT count(id) AS count FROM tool_uses USE INDEX (index_tool_uses_on_tool_id_and_created_at) WHERE tool_id = ? AND created_at >= ?", tool_id, 1.week.ago ] )[0].count.to_i rescue 0
          counts.monthly += ToolUse.find_by_sql( [ "SELECT count(id) AS count FROM tool_uses USE INDEX (index_tool_uses_on_tool_id_and_created_at) WHERE tool_id = ? AND created_at >= ?", tool_id, 1.month.ago ] )[0].count.to_i rescue 0
          counts.overall += ToolUse.find_by_sql( [ "SELECT count(id) AS count FROM tool_uses USE INDEX (index_tool_uses_on_tool_id_and_created_at) WHERE tool_id = ?", tool_id ] )[0].count.to_i rescue 0
        end
        counts
      end
    end
  end
  
  def self.chaos_counts
    get_cache('chaos_point_count', :ttl => 2.days) do
      # First we need to grab the IDs of the various tools in the Order side.
      # We do this to avoid the possiblity of stale data.
      ToolUse.slave_setup do
        mine_id = Tool.cached_single('mines').id
        portal_id = Tool.cached_single('portals').id
        st_nick_id = Tool.cached_single('st_nicks').id
        watchdog_id = Tool.cached_single('watchdogs').id

        counts = OpenStruct.new
        counts.daily = counts.weekly = counts.monthly = counts.overall = 0
        [mine_id, portal_id, st_nick_id, watchdog_id].each do |tool_id|
          counts.daily += ToolUse.count(:conditions => [ 'tool_id = ? and created_at >= ?', tool_id, 1.day.ago ]) 
          counts.weekly += ToolUse.count(:conditions => [ 'tool_id = ? and created_at >= ?', tool_id, 1.week.ago ])
          counts.monthly += ToolUse.count(:conditions => [ 'tool_id = ? and created_at >= ?', tool_id, 1.month.ago ])
          counts.overall += ToolUse.count(:conditions => [ 'tool_id = ?', tool_id ])
        end
        counts
      end
    end
  end
  
  protected
  def before_create
    self.id = create_uuid
  end
end
