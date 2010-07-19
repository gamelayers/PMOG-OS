class AddCreatedAtToActiveAndReactiveUsersForDebugging < ActiveRecord::Migration
  def self.up
    add_column :active_users, :created_at, :datetime
    add_column :reactive_users, :created_at, :datetime

    ActiveUser.find(:all).each do |u|
      u.created_at = u.date.to_time
      u.save
    end

    ReactiveUser.find(:all).each do |u|
      u.created_at = u.date.to_time
      u.save
    end
  end

  def self.down
    remove_column :active_users, :created_at
    remove_column :reactive_users, :created_at
  end
end
