class CreateDailyActivities < ActiveRecord::Migration
  def self.up
    create_table :daily_activities, :id => false do |t|
      t.string :id, :limit => 36, :null => false
      t.string :user_id, :limit => 36, :null => false
      t.string :extension_version, :null => false
      t.string :created_on, :null => false
    end
    
    add_index :daily_activities, :id
    add_index :daily_activities, :user_id
    add_index :daily_activities, :extension_version
    add_index :daily_activities, :created_on
  end

  def self.down
    drop_table :daily_activities
  end
end