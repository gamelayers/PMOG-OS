# == Schema Information
# Schema version: 20081220201004
#
# Table name: tools
#
#  id                :string(36)    primary key
#  name              :string(255)   not null
#  cost              :integer(11)   default(0), not null
#  character         :string(255)   not null
#  short_description :string(255)   
#  small_image       :string(255)   
#  large_image       :string(255)   
#  charges           :integer(11)   default(0)
#  long_description  :text          
#  history           :text          
#  damage            :integer(11)   default(0)
#  created_at        :datetime      
#  updated_at        :datetime      
#  medium_image      :string(255)   not null
#  icon_image        :string(255)   not null
#  association_cost  :integer(11)   default(0), not null
#  level             :integer(11)   default(1)
#

class Tool < ActiveRecord::Base
  acts_as_taggable
  acts_as_cached

  belongs_to :pmog_class

  after_save :expire_cache
  
  @@discount_level_threshold = 5
  cattr_reader :discount_level_threshold
  
  @@private_api_fields = %w(id charges history damage created_at updated_at association_cost)
  cattr_reader :private_api_fields

  @@included_api_associations = []
  cattr_reader :included_api_associations

  def self.cached_single(tool_name)
    get_cache(tool_name.to_sym) do
      find( :first, :conditions => { :url_name => tool_name.to_s} )
    end
  end
  
	def self.cached_multi
    get_cache(:multi) do 
      find(:all, :order => :id)
    end
	end

#	DEPRECATED 09-02-10 by alex, we havent used this for a while so i'm putting it officially out of comission
#  # Returns the discounted cost if the user is of a matching association
#	def lowest_cost_for(user)
#    cost
#	  #(user.associations.include?(character.downcase) or user.associations.include?('shoat') or user.current_level < self.discount_level_threshold) ? association_cost : cost
#  end

  # Is the price of this tool discounted for this +user+
  def discounted?(user)
    false
	  #(user.associations.include?(character.downcase) or user.associations.include?('shoat') or user.current_level < self.discount_level_threshold) ? true : false
  end

#  # this is hackery, but i need it for polymorphism w/ [Tools, Upgrades, Abilities] and UserLevels
#  def url_name
#    self.name
#  end
	
  def before_create
    self.id = create_uuid
  end
end
