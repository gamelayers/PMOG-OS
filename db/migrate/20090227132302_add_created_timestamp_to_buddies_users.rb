class AddCreatedTimestampToBuddiesUsers < ActiveRecord::Migration
  def self.up
    add_timestamps :buddies_users
  end

  def self.down
    remove_timestamps :buddies_users
  end
end
