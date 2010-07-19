# == Schema Information
# Schema version: 20081220201004
#
# Table name: unsubscribe_requests
#
#  id         :string(36)    primary key
#  user_id    :string(36)    
#  confirmed  :boolean(1)    
#  created_at :datetime      
#  updated_at :datetime      
#

class UnsubscribeRequest < ActiveRecord::Base
  
belongs_to :user
  
def before_create
  self.id = create_uuid
end
  
end
