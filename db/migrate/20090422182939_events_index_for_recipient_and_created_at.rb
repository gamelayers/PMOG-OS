class EventsIndexForRecipientAndCreatedAt < ActiveRecord::Migration
  def self.up
    add_index :events, [:recipient_id, :created_at]
  end

  def self.down
    remove_index :events, [:recipient_id, :created_at]
  end
end
