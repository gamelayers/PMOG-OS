class DailyActivityCompoundIndex < ActiveRecord::Migration
  # This compound index should make DailyActivity.record much quicker, since it cuts down
  # on the rows scanned. This is worth doing since we hit DailyActivity.record a lot, as it
  # runs as a result of users pinging the site regularly.
  def self.up
    remove_index :daily_activities, :user_id
    remove_index :daily_activities, :extension_version
    remove_index :daily_activities, :created_on
    execute "CREATE INDEX `recorder` ON `daily_activities` (`user_id`, `extension_version`, `created_on`)"
  end

  def self.down
    execute "DROP INDEX `recorder` ON daily_activities"
    add_index :daily_activities, :user_id
    add_index :daily_activities, :extension_version
    add_index :daily_activities, :created_on
  end
end
