class MessagesIndexWork < ActiveRecord::Migration
  def self.up
    # these are redundant
    execute "alter table messages drop index index_messages_on_feed_id, drop index index_messages_on_user_id, drop index index_messages_on_recipient_id_and_read_at"
  end

  def self.down
    add_index :messages, :feed_id
    add_index :messages, :user_id
    add_index :messages, [:recipient_id, :read_at]
  end
end
