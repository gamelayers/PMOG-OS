class CreateBirdBots < ActiveRecord::Migration
  def self.up
    create_table :bird_bots, :id => false do |t|
      t.column :id, :string, :login => 36
      t.column :user_id, :string, :login => 36
      t.column :feed_id, :string, :limit => 36
      t.column :name, :string, :limit => 255
      t.column :url_name, :string, :limit => 255
      t.column :description, :text
      t.column :first_words, :string
    end

    create_table :bird_bots_locations, :id => false do |t|
      t.column :bird_bot_id, :string, :limit => 36
      t.column :location_id, :string, :limit => 36
    end

    create_table :bird_bots_users, :id => false do |t|
      t.column :bird_bot_id, :string, :limit => 36
      t.column :user_id, :string, :limit => 36
    end

    add_index :bird_bots, :id
    add_index :bird_bots, :user_id
    add_index :bird_bots, :feed_id
    add_index :bird_bots, :url_name
    add_index :bird_bots_locations, :bird_bot_id
    add_index :bird_bots_locations, :location_id
    add_index :bird_bots_users, :bird_bot_id
    add_index :bird_bots_users, :user_id
  end

  def self.down
    drop_table :bird_bots
    drop_table :bird_bots_locations
    drop_table :bird_bots_users
  end
end