class PreferencesIndexWork < ActiveRecord::Migration
  def self.up
    # redundant
    remove_index :preferences, :user_id
  end

  def self.down
    add_index :preferences, :user_id
  end
end
