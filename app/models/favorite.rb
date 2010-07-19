# == Schema Information
# Schema version: 20081220201004
#
# Table name: favorites
#
#  user_id        :string(36)    
#  favorable_type :string(30)    
#  favorable_id   :string(36)    
#  created_at     :datetime      
#  updated_at     :datetime      
#  id             :string(36)    primary key
#

# Defines named favorites for users that may be applied to objects in a polymorphic fashion.
class Favorite < ActiveRecord::Base
  belongs_to :user
  belongs_to :favorable, :polymorphic => true
  
  # Make sure we use UUIDs for favorites
  def before_create
    self.id = create_uuid
  end
  
end
