class UuiDsInChannelsUsers < ActiveRecord::Migration
  def self.up
    remove_column :channels_users, :user_id
    add_column :channels_users, :user_id, :string, :limit => 36
  end

  def self.down
    remove_column :channels_users, :user_id
    add_column :channels_users, :user_id, :int, :limit => 11
  end
end
