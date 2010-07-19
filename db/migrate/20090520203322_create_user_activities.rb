class CreateUserActivities < ActiveRecord::Migration
  def self.up
    create_table :user_activities do |t|
      t.timestamps
      t.timestamp :activity_at, :default => nil
      t.string :user_id, :limit => 36, :null => false
      t.string :extension_version
    end

    add_index :user_activities, [:created_at, :user_id]
    add_index :user_activities, [:user_id, :created_at]
  
    add_index :user_activities, [:activity_at, :user_id]
    add_index :user_activities, [:user_id, :activity_at]
  end

  def self.down
    remove_index :user_activities, [:activity_at, :user_id]
    remove_index :user_activities, [:user_id, :activity_at]
    remove_index :user_activities, [:created_at, :user_id]
    remove_index :user_activities, [:user_id, :created_at]
    drop_table :user_activities
  end
end
