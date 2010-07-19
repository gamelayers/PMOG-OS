# == Schema Information
# Schema version: 20081220201004
#
# Table name: missionatings
#
#  mission_id :string(36)    
#  user_id    :string(36)    
#  created_at :datetime      
#  updated_at :datetime      
#

class Missionating < ActiveRecord::Base
  belongs_to :mission
  belongs_to :user
end
