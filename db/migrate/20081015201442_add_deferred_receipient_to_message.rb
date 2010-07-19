class AddDeferredReceipientToMessage < ActiveRecord::Migration
  def self.up
    add_column :messages, :deferred_recipient_id, :string, :limit => 36
  end

  def self.down
    remove_column :messages, :deferred_recipient_id
  end
end
