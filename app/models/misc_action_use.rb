class MiscActionUse < ActiveRecord::Base
  acts_as_cached

  belongs_to :misc_action
  belongs_to :user

  validates_presence_of :misc_action_id, :user_id
  
  # How many of misc_action x were used, or how many of misc_action x did user y use?
  def self.total(misc_action, user = nil, usage_type = 'misc_action')
    get_cache( "misc_action_use_total_#{misc_action}_#{user}" ) {
      if user
        count( :conditions => { :misc_action_id => misc_action.id, :user_id => user.id } )
      else
        count( :conditions => { :misc_action_id => misc_action.id } )
      end
    }
  end

  protected
  def before_create
    self.id = create_uuid
  end
end
