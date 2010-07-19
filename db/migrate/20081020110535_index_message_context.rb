class IndexMessageContext < ActiveRecord::Migration
  def self.up
    add_index :messages, :context
  end

  def self.down
    remove_index :messages, :context
  end
end
