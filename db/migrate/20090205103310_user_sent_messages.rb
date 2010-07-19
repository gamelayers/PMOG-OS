class UserSentMessages < ActiveRecord::Migration
  def self.up
    add_index :messages, [:user_id, :created_at]
  end

  def self.down
    remove_index :messages, [:user_id, :created_at]
  end
end
