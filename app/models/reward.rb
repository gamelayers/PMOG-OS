class Reward < ActiveRecord::Base
  belongs_to :rewardable, :polymorphic => true
  has_one :tool
  
  validates_numericality_of :level, :on => :create, :message => "is not a number"
  
  def before_create
    self.id = create_uuid
  end
end
