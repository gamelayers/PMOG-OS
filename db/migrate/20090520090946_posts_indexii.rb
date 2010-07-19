class PostsIndexii < ActiveRecord::Migration
  def self.up
    remove_index :posts, [:user_id]
    add_index :posts, [:user_id, :created_at]
  end

  def self.down
    add_index :posts, [:user_id]
    remove_index :posts, [:user_id, :created_at]
  end
end
