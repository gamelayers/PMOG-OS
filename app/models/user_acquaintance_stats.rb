# == Schema Information
# Schema version: 20081220201004
#
# Table name: user_acquaintance_stats
#
#  id                 :string(36)    not null, primary key
#  user_count         :integer(11)   
#  acquaintance_count :integer(11)   
#  created_at         :datetime      
#  updated_at         :datetime      
#

class UserAcquaintanceStats < ActiveRecord::Base
  
  def before_create
    self.id = create_uuid
  end
  
end
