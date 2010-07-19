# == Schema Information
# Schema version: 20081220201004
#
# Table name: transportations
#
#  portal_id  :string(36)    
#  user_id    :string(36)    
#  created_at :datetime      
#  updated_at :datetime      
#

class Transportation < ActiveRecord::Base
  belongs_to :portal
  belongs_to :user
end
