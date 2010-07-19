# == Schema Information
# Schema version: 20081220201004
#
# Table name: badgings
#
#  badge_id   :string(36)    
#  user_id    :string(36)    
#  created_at :datetime      
#  updated_at :datetime      
#

class Badging < ActiveRecord::Base
  belongs_to :badge
  belongs_to :user
end
