class CreateTopics < ActiveRecord::Migration
  def self.up
    create_table :topics, :id => false do |t|
      t.column :id, :string, :limit => 36
      t.column :user_id, :string, :limit => 36
      t.column :forum_id, :string, :limit => 36
      t.column :title, :string
      t.column :description, :text
      t.column :url_name, :string, :limit => 255
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
    end
    
    add_index :topics, :id
    add_index :topics, :user_id
    add_index :topics, :forum_id
    add_index :topics, :url_name

  end

  def self.down
    drop_table :topics
  end
end
