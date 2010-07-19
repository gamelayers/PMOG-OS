#NOTE
#this class is just a stub; its left here in order to make the full migration stack function still
class OldInventory < ActiveRecord::Base
  # Used to track the person who put the item here, not whose inventory it belongs in
  belongs_to :user

  belongs_to :tool
  belongs_to :item
  belongs_to :crate
  belongs_to :slottable, :polymorphic => true
	
  def before_create
    self.id = create_uuid
  end
end
