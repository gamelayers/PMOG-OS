class UserLoginTracking < ActiveRecord::Migration
  # These fields will allow us to limit the number of login attempts from users,
  # mainly to prevent scripted login attempts from dictionary attacks.
  # - remote ip so that we can deny logins on a per-ip basis, and also so that 
  # a user can't lock your account mischeivously
  # - last_login_attempt so that we can block logins for 60 seconds to massively
  # slow down a scripted attack
  # - failed_login_attempts so that we can count how many attempts are taking place
  # and block users above a certain threshold
  # - locked so that we can lock an account if we really need to.
  def self.up
    add_column :users, :remote_ip, :string
    add_column :users, :last_login_attempt, :datetime
    add_column :users, :failed_login_attempts, :integer, :default => 0
    add_column :users, :locked, :boolean, :default => 0
  end

  def self.down
    remove_column :users, :remote_ip
    remove_column :users, :last_login_attempt
    remove_column :users, :failed_login_attempts
    remove_column :users, :locked
  end
end
