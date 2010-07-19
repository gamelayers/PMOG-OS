class EventsIndex < ActiveRecord::Migration
  def self.up
    add_index :events, [:recipient_id, :created_at, :user_id]
  end

  def self.down
    remove_index :events, [:recipient_id, :created_at, :user_id]
  end
end
