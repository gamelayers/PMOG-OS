class EventsIndexWork < ActiveRecord::Migration
  def self.up
    execute("alter table events drop index index_events_on_user_id, drop index index_events_on_recipient_id, drop index index_events_on_recipient_id_and_created_at");
  end

  def self.down
    add_index :events, :user_id
    add_index :events, :recipient_id
    add_index :events, [:recipient_id, :created_at]
  end
end
