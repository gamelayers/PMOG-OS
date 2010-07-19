# == Schema Information
# Schema version: 20081220201004
#
# Table name: ratings
#
#  id            :string(36)    default(""), not null, primary key
#  score         :integer(11)   default(0)
#  rateable_type :string(255)   
#  rateable_id   :string(36)    
#  user_id       :string(36)    
#  updated_at    :datetime      
#  created_at    :datetime      
#

class Rating < ActiveRecord::Base
  belongs_to :rateable, :polymorphic => true
  belongs_to :user, :counter_cache => true
  
  acts_as_cached
  
  # Restricted attributes and included association for JSON output
  cattr_accessor :private_api_fields, :included_api_associations
  @@private_api_fields = []
  @@included_api_associations = []
  
  def before_create
    self.id = create_uuid
  end
end
