# == Schema Information
# Schema version: 20081220201004
#
# Table name: stewardings
#
#  user_id          :string(36)    
#  action           :string(255)   
#  created_at       :datetime      
#  updated_at       :datetime      
#  stewardable_id   :string(36)    
#  stewardable_type :string(255)   
#

class Stewarding < ActiveRecord::Base
  
  belongs_to :user
  belongs_to :stewardable, :polymorphic => true
  
  def verbed_action
    case self.action
      when 'delete_assets':
        'deleted the assets of'
      when 'pin', 'unpin':
        self.action + 'ned'
      else
        self.action + 'ed'
    end
  end
end
