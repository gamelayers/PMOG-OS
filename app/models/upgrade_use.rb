# == Schema Information
# Schema version: 20081220201004
#
# Table name: upgrade_uses
#
#  id         :string(36)    default(""), not null, primary key
#  upgrade_id :string(36)    
#  user_id    :string(36)    
#  points     :integer(11)   
#  created_at :datetime      
#  updated_at :datetime      
#

# tracking upgrade uses just like the ToolUse class.  used for association tracking and order vs chaos.
class UpgradeUse < ActiveRecord::Base
  acts_as_cached

  belongs_to :upgrade
  belongs_to :user

  validates_presence_of :upgrade_id, :user_id
  
  # How many of upgrade x were used, or how many of upgrade x did user y use?
  def self.total(upgrade, user = nil, usage_type = 'upgrade')
    get_cache( "upgrade_use_total_#{upgrade}_#{user}" ) {
      if user
        count( :conditions => { :upgrade_id => upgrade.id, :user_id => user.id } )
      else
        count( :conditions => { :upgrade_id => upgrade.id } )
      end
    }
  end

  protected
  def before_create
    self.id = create_uuid
  end
end
