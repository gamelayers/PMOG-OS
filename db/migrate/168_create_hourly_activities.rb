class CreateHourlyActivities < ActiveRecord::Migration
  def self.up
    create_table :hourly_activities, :id => false do |t|
      t.string :id, :limit => 36, :null => false
      t.string :user_id, :limit => 36, :null => false
      t.string :extension_version, :null => false
      t.string :hour, :limit => 2, :null => false
      t.timestamps
    end

    # Note that the compound index below, copied from daily_activites
    add_index :hourly_activities, :id
    execute "CREATE INDEX `recorder` ON `hourly_activities` (`user_id`, `extension_version`, `created_at`, `hour`)"
  end

  def self.down
    drop_table :hourly_activities
  end
end
