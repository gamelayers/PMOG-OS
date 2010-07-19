# == Schema Information
# Schema version: 20081220201004
#
# Table name: layouts
#
#  id         :integer(11)   not null, primary key
#  name       :string(255)   default("order")
#  created_at :datetime      
#  updated_at :datetime      
#

# Deprecated



# The website will have one layout if chaos is winning and another if 
# order is winning. This is set via a daily cron job.
class Layout < ActiveRecord::Base
  acts_as_cached
  after_save :expire_cache
  
  # Set the current layout based on which faction is winning
  def self.set_current(chaos, order)
    current_layout = Layout.find :first
    if chaos > order
      current_layout.name = 'chaos'
    else
      current_layout.name = 'order'
    end
    current_layout.save
  end
  
  # Returns the current cached layout
  def self.cached_current
    get_cache(:layout_current) do 
      Layout.current
    end
  end
  
  # Returns the current layout
  def self.current
    @current ||= Layout.find(:first).name
  end
end
