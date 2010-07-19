# == Schema Informationi
# Schema version: 20081220201004
#
# Table name: upgrades
#
#  id                :string(36)    default(""), not null, primary key
#  name              :string(255)   
#  url_name          :string(255)   
#  tool_id           :string(36)    
#  association_id    :string(36)    
#  level             :integer(11)   
#  short_description :string(255)   
#  icon_image        :string(255)   
#  small_image       :string(255)   
#  medium_image      :string(255)   
#  large_image       :string(255)   
#  long_description  :text          
#  history           :text          
#  dp_cost           :integer(11)   
#  ping_cost         :integer(11)   
#  armor_cost        :integer(11)   default(0)
#  crate_cost        :integer(11)   default(0)
#  lightpost_cost    :integer(11)   default(0)
#  mine_cost         :integer(11)   default(0)
#  portal_cost       :integer(11)   default(0)
#  st_nick_cost      :integer(11)   default(0)
#  damage            :integer(11)   default(0)
#  misc              :integer(11)   
#  created_at        :datetime      
#  updated_at        :datetime      
#

class Upgrade < ActiveRecord::Base
  acts_as_cached

  belongs_to :pmog_class

  class UpgradeError < PMOG::PMOGError;
    def default
      "Something has caused your upgrade to fail"
    end
  end

#  @@private_api_fields = %w(id charges history damage created_at updated_at association_cost)
#  cattr_reader :private_api_fields

  def after_save
    Upgrade.expire_single(self.url_name.to_s)
  end

  def self.expire_single(upgrade_name)
    expire_cache(upgrade_name.to_sym)
  end

  def self.cached_single(upgrade_name)
    get_cache(upgrade_name.to_sym) do
      find( :first, :conditions => { :url_name => upgrade_name.to_s} )
    end
  end
  
	def self.cached_multi
    get_cache(:multi) do 
      find(:all, :order => :id)
    end
	end
	
  def before_create
    self.id = create_uuid
  end
end
