class SuspendedIndices < ActiveRecord::Migration
  def self.up
    add_index :suspensions, [:user_id, :expires_at]
  end

  def self.down
    remove_index :suspensions, [:user_id, :expires_at]
  end
end
