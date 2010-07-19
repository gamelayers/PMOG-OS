# == Schema Information
# Schema version: 20081220201004
#
# Table name: motd
#
#  id         :string(36)    not null, primary key
#  title      :string(255)   
#  body       :text          not null
#  created_at :datetime      
#  updated_at :datetime      
#

# MOTDs are Message Of The Day(s)
# Note that they differ from normal messages in that they are sent to *every* user
# of PMOG. These are global messages only. For user-to-user or group IMs, use +Message+
class Motd < ActiveRecord::Base
  acts_as_cached

  # Protect internal methods from mass-update.
  attr_accessible :title, :body

  @@private_api_fields = []
  @@included_api_associations = []

  validates_presence_of :body
  validates_length_of :body, :maximum => 1000

  has_many :dismissals, :as => :dismissable, :dependent => :destroy, :extend => DismissableExtension

  # Returns the single most recent +Motd+
  def self.latest
    find( :first, :order => 'created_at DESC' )
  end

  protected
  def before_create
    self.id = create_uuid
  end
end
