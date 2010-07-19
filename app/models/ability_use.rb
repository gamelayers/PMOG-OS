# tracking ability uses just like the ToolUse class.  used for association tracking and order vs chaos.
class AbilityUse < ActiveRecord::Base
  acts_as_cached

  belongs_to :ability
  belongs_to :user

  validates_presence_of :ability_id, :user_id
  
  # How many of ability x were used, or how many of ability x did user y use?
  def self.total(ability, user = nil, usage_type = 'ability')
    get_cache( "ability_use_total_#{ability}_#{user}", :ttl => 1.day ) {
      if user
        count( :conditions => { :ability_id => ability.id, :user_id => user.id } )
      else
        count( :conditions => { :ability_id => ability.id } )
      end
    }
  end

  protected
  def before_create
    self.id = create_uuid
  end
end
