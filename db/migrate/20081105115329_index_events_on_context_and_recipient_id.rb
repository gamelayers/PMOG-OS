class IndexEventsOnContextAndRecipientId < ActiveRecord::Migration
  def self.up
    remove_index :events, :context
    add_index :events, [:context, :recipient_id]
  end

  def self.down
    add_index :events, :context
    remove_index :events, [:context, :recipient_id]
  end
end
