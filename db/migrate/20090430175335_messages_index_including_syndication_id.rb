class MessagesIndexIncludingSyndicationId < ActiveRecord::Migration
  def self.up
    # We have an index on recipient_id, created_at and read_at, so it's safe to drop these two
#    remove_index :messages, :recipient_id
#    remove_index :messages, [:recipient_id, :created_at]

    add_index :messages, [:recipient_id, :syndication_id, :created_at]
  end

  def self.down
    add_index :messages, :recipient_id
    add_index :messages, [:recipient_id, :created_at]
    remove_index :messages, [:recipient_id, :syndication_id, :created_at]
  end
end
