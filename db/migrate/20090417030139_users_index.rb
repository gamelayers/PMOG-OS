class UsersIndex < ActiveRecord::Migration
  def self.up
    add_index :users, :created_at
  end

  def self.down
    remove_index :users, :created_at
  end
end
