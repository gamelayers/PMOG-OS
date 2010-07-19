class Ability < ActiveRecord::Base
  acts_as_cached

  belongs_to :pmog_class

  class AbilityError < PMOG::PMOGError;
    def default
      "Something has caused your ability to fail.  Please try again."
    end
  end

  def after_save
    Ability.expire_single(self.url_name.to_s)
  end

  def self.expire_single(ability_name)
    expire_cache(ability_name.to_sym)
  end

  def self.cached_single(ability_name)
    get_cache(ability_name.to_sym) do
      find( :first, :conditions => { :url_name => ability_name.to_s} )
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
