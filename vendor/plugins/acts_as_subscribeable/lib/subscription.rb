class Subscription < ActiveRecord::Base
  belongs_to :subscribeable, :polymorphic => true
  belongs_to :user
  
  def before_create
     self.id = create_uuid
  end
  
  # Helper class method to lookup all subscriptions assigned
  # to all subscribeable types for a given user.
  def self.find_subscriptions_by_user(user)
    self.find(
      :all,
      :conditions => ["user_id = ?", user],
      :order => "created_at DESC"
    )
  end
  
end