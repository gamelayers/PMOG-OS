# == Schema Information
# Schema version: 20081220201004
#
# Table name: takings
#
#  id         :string(36)    not null, primary key
#  mission_id :string(36)    not null
#  user_id    :string(36)    not null
#  created_at :datetime      
#  updated_at :datetime      
#

class Taking < ActiveRecord::Base
  
  belongs_to :mission, :polymorphic => true
  belongs_to :user
  
  def before_create
    self.id = create_uuid
  end
  
end
