class UserActivity < ActiveRecord::Base
  belongs_to :user
  def self.update(user, extension_version)
    user.reward_paycheck

    activity = UserActivity.find(:first, :conditions => [ "user_id = ?", user.id])
    #activity = UserActivity.find_or_create_by_user(user)
    if activity.nil?
      activity = UserActivity.new(:user => user, :extension_version=>extension_version)
    end
    if activity.updated_at.nil? || ((Time.now.utc - activity.updated_at) > (15 * 60)) # more than an hour
      activity.activity_at = Time.now.utc
      activity.save
    end

  end
end
