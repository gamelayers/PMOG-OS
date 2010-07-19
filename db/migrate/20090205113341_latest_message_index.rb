class LatestMessageIndex < ActiveRecord::Migration
  def self.up
    add_index :messages, [:recipient_id, :read_at, :created_at]
  end

  def self.down
    remove_index :messages, [:recipient_id, :read_at, :created_at]
  end
end
