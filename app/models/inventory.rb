class Inventory < ActiveRecord::Base
  belongs_to :owner, :polymorphic => true

  # FIXME can't figure out how to circumnavigate having this 
  def to_hash 
    Hash[ 
      :crates => self.crates, 
      :grenades => self.grenades, 
      :lightposts => self.lightposts, 
      :mines => self.mines, 
      :portals => self.portals, 
      :armor => self.armor, 
      :st_nicks => self.st_nicks, 
      :skeleton_keys => self.skeleton_keys,
      :watchdogs => self.watchdogs] 
  end
	
  def before_create
    self.id = create_uuid
  end
end
