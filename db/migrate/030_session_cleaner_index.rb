class SessionCleanerIndex < ActiveRecord::Migration
  def self.up
    add_index :sessions, :updated_at
  end

  def self.down
    remove_index :sessions, :updated_at
  end
end
