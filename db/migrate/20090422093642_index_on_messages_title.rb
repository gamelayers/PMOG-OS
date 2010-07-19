class IndexOnMessagesTitle < ActiveRecord::Migration
  def self.up
    add_index :messages, :title
  end

  def self.down
    remove_index :messages, :title
  end
end
