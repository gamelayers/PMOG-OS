class UserLastLoginAt < ActiveRecord::Migration
  def self.up
    add_index :users, :last_login_at
  end

  def self.down
    remove_index :users, :last_login_at
  end
end
