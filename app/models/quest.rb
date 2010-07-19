class Quest < ActiveRecord::Base
  has_many :goals, :order => "position"
  has_many :rewards, :as => :rewardable
  belongs_to :user
  
  has_friendly_id :name, :use_slug => true

  Associations = {
    :bedouin => "Bedouin",
    :benefactor => "Benefactor",
    :destroyer => "Destroyer",
    :pathmaker => "Pathmaker",
    :seer => "Seer",
    :vigilante => "Vigilante",
    :shoat => "Shoat",
    :any => "Any"
  }

  validates_inclusion_of :association, :in => Associations.values, :on => :update, :if => :should_validate_association?, :message => "is not an allowed association"
  validates_presence_of :association, :on => :update, :if => :should_validate_association?, :message => "can't be blank"
  validates_numericality_of :level, :if => :should_validate_level?, :message => "is not a number"
  validates_presence_of :name, :message => "can't be blank"
  validates_presence_of :user_id, :message => "can't be blank"
  
  attr_accessor :updating_level
  attr_accessor :updating_association
  
  def before_create
    self.id = create_uuid
  end

  def should_validate_level?
    updating_level
  end

  def should_validate_association?
    updating_association
  end
  
end
