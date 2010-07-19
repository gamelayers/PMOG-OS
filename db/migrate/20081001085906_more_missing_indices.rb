class MoreMissingIndices < ActiveRecord::Migration
  def self.up
    #remove_index :buddies_users, :accepted
    #add_index :buddies_users, [:user_id, :accepted]

    #remove_index :badges_users, :user_id
    #add_index :badges_users, [:user_id, :created_at]

    #add_index :users, :created_at

    #add_index :levels, :level

    #add_index :daily_log_ins, [:user_id, :created_at]

    add_index :daily_activities, [:user_id, :created_on]

    add_index :events, [:user_id, :created_at]

    add_index :preferences, [:user_id, :created_at]
  end

  def self.down
    #add_index :buddies_users, :accepted
    #remove_index :buddies_users, [:user_id, :accepted]

    #add_index :badges_users, :user_id
    #remove_index :badges_users, [:user_id, :created_at]

    #remove_index :users, :created_at

    #remove_index :levels, :level
    
    #remove_index :daily_log_ins, [:user_id, :created_at]

    remove_index :daily_activities, [:user_id, :created_on]

    remove_index :events, [:user_id, :created_at]

    remove_index :preferences, [:user_id, :created_at]
  end
end
