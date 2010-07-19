class LatestMessages < ActiveRecord::Migration
  def self.up
    add_index :messages, [:recipient_id, :created_at]
  end

  def self.down
    remove_index :messages, [:recipient_id, :created_at]
  end
end
