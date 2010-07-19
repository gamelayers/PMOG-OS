class AddMessageCounterCache < ActiveRecord::Migration
  def self.up
    add_column :users, :received_messages_count, :integer, :null => false, :default => 0
  end

  def self.down
    remove_column :users, :received_messages_count
  end
end
