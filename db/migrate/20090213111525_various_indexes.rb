# To speed up the newly redesigned profile, we need to index
# a lot of data in a lot of different ways. Here's a bunch of 
# indices to help us do that - duncan 13/02/09
class VariousIndexes < ActiveRecord::Migration
  def self.up
    add_index :missionatings, [:user_id, :created_at]
    add_index :favorites, [:user_id, :favorable_type, :created_at]
    execute( "ALTER TABLE abilities ADD PRIMARY KEY(id)" )
    add_index :abilities, :url_name
    execute( "ALTER TABLE ability_uses ADD PRIMARY KEY(id)" )
    add_index :ability_uses, [:user_id, :ability_id]
    add_index :pmog_classes, :name
    add_index :subscriptions, :user_id
    add_index :levels, [:classpoints, :datapoints, :level]
    remove_index :missions, :user_id
    add_index :missions, [:user_id, :is_active, :created_at]
    remove_index :posts, :topic_id
    add_index :posts, [:topic_id, :is_active, :created_at]
  end

  def self.down
    remove_index :missionatings, [:user_id, :created_at]
    remove_index :favorites, [:user_id, :favorable_type, :created_at]
    execute( "ALTER TABLE abilities DROP PRIMARY KEY" )
    remove_index :abilities, :url_name
    execute( "ALTER TABLE ability_uses DROP PRIMARY KEY" )
    remove_index :ability_uses, [:user_id, :ability_id]
    remove_index :subscriptions, :user_id
    remove_index :levels, [:classpoints, :datapoints, :level]
    add_index :missions, :user_id
    remove_index :missions, [:user_id, :is_active, :created_at]
    add_index :posts, :topic_id
    remove_index :posts, [:topic_id, :is_active, :created_at]
    
    begin
      remove_index :pmog_classes, :name
    rescue
      puts "Don't know why this fails, bah"
    end
  end
end