class Goal < ActiveRecord::Base
    
  belongs_to :quest
  belongs_to :user
  has_one :tool
  has_one :location
  has_one :action
  has_many :rewards, :as => :rewardable
  
  acts_as_list :scope => 'quest_id = \'#{quest_id}\''
  
  validates_presence_of :count
  validates_presence_of :action_id
  
  def before_create
    self.id = create_uuid
  end
  
  def url
    if not self.location_id.nil? and not self.location_id.empty?
      return Location.find(self.location_id).url
    else
      # We have to return an empty string here because it populates the
      # form's location text box with the url value. If it's nil ruby pukes.
      # So if there's no url return empty.
      return ""
    end
  end
  
end
