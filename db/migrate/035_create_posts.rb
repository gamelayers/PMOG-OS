class CreatePosts < ActiveRecord::Migration
  def self.up
    create_table :posts, :id => false do |t|
      t.column :id, :string, :limit => 36
      t.column :user_id, :string, :limit => 36
      t.column :topic_id, :string, :limit => 36
      t.column :body, :text
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
    end

    add_index :posts, :id
    add_index :posts, :user_id
    add_index :posts, :topic_id
  end

  def self.down
    drop_table :posts
  end
end
