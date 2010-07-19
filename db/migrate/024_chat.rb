class Chat < ActiveRecord::Migration
  def self.up
    create_table :channels do |t|
      t.column "name", :string, :limit => 255
      t.column "title", :string, :limit => 255
      t.column "private", :int, :limit => 4, :default => 0
      t.column "topic", :string, :lmit => 255
    end

    add_index "channels", ["name"], :name => "name"

    create_table :channels_users, :id => false do |t|
      t.column "channel_id", :int, :limit => 11
      t.column "user_id", :int, :limit => 11
      t.column "last_seen", :datetime
    end

    add_index "channels_users", ["last_seen"], :name => "last_seen"

    create_table :chat_messages, :id => false do |t|
      t.column :id, :string, :limit => 36
      t.column "created_at", :datetime
      t.column "type", :string
      t.column "content", :text
      t.column "channel_id", :int, :limit => 11
      t.column "sender_id", :string, :limit => 36
      t.column "level", :string
      t.column "recipient_id", :string, :limit => 36
    end

    add_index "chat_messages", ["created_at"], :name => "created_at"
    add_index "chat_messages", ["sender_id"], :name => "sender_id"
  end

  def self.down
    drop_table :channels
    drop_table :channels_users
    drop_table :chat_messages
  end
end