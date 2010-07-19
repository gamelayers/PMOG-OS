# == Schema Information
# Schema version: 20081220201004
#
# Table name: transactions
#
#  id         :string(36)    primary key
#  user_id    :string(36)    
#  action     :string(36)    
#  item       :string(36)    
#  amount     :integer(11)   
#  comment    :text          
#  created_at :datetime      
#  updated_at :datetime      
#

class Transaction < ActiveRecord::Base
  
  # Ensure a uuid primary key
  def before_create
    self.id = create_uuid
  end
  
end
