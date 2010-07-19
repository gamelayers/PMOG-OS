class MiscAction < ActiveRecord::Base
  acts_as_cached

  class MiscActionError < PMOG::PMOGError;
    def default
      "Something has caused your action to fail.  Please try again."
    end
  end

  def after_save
    MiscAction.expire_single(self.url_name.to_s)
  end

  def self.expire_single(misc_action_name)
    expire_cache(misc_action_name.to_sym)
  end

  def self.cached_single(misc_action_name)
    get_cache(misc_action_name.to_sym) do
      find( :first, :conditions => { :url_name => misc_action_name.to_s} )
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
