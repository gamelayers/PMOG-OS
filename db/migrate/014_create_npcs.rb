class CreateNpcs < ActiveRecord::Migration
  def self.up
    create_table :npcs, :id => false do |t|
      t.column :id, :string, :limit => 36
      t.column :user_id, :string, :limit => 36
      t.column :name, :string, :limit => 255
      t.column :url_name, :string, :limit => 255
      t.column :description, :text
      t.column :first_words, :string
    end
    
    create_table :npcs_locations, :id => false do |t|
      t.column :npc_id, :string, :limit => 36
      t.column :location_id, :string, :limit => 36
    end

    create_table :npcs_feeds, :id => false do |t|
      t.column :npc_id, :string, :limit => 36
      t.column :feed_id, :string, :limit => 36
    end

    create_table :npcs_users, :id => false do |t|
        t.column :npc_id, :string, :limit => 36
        t.column :user_id, :string, :limit => 36
      end
      
    add_index :npcs, :id
    add_index :npcs, :user_id
    add_index :npcs, :url_name
    add_index :npcs_feeds, :npc_id
    add_index :npcs_feeds, :feed_id    
    add_index :npcs_locations, :npc_id
    add_index :npcs_locations, :location_id
    add_index :npcs_users, :npc_id
    add_index :npcs_users, :user_id
  end

  def self.down
    drop_table :npcs
    drop_table :npcs_feeds
    drop_table :npcs_locations
    drop_table :npcs_users
  end
end