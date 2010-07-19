class AddRecentSignupToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :recent_signup, :boolean, :default => true
  end

  def self.down
    remove_column :users, :recent_signup
  end
end
