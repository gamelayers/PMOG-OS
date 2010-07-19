class UpdateAllExistingUsersRecentSignup < ActiveRecord::Migration
  def self.up
    User.reset_column_information
    User.update_all(:recent_signup => false)
  end

  def self.down
  end
end
