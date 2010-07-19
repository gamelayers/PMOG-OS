# == Schema Information
# Schema version: 20081220201004
#
# Table name: dismissals
#
#  id               :string(36)    default(""), not null, primary key
#  dismissable_type :string(255)   
#  dismissable_id   :string(36)    
#  user_id          :string(36)    
#  created_at       :datetime      
#  updated_at       :datetime      
#

class Dismissal < ActiveRecord::Base
  belongs_to :dismissable, :polymorphic => true
  belongs_to :user
  
  acts_as_cached

  # Restricted attributes and included association for JSON output
  cattr_accessor :private_api_fields, :included_api_associations
  @@private_api_fields = []
  @@included_api_associations = []
  
  def before_create
    self.id = create_uuid
  end
end
