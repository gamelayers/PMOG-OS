class CommentsIndex < ActiveRecord::Migration
  def self.up
    add_index :comments, [:commentable_id, :created_at]
  end

  def self.down
    remove_index :comments, [:commentable_id, :created_at]
  end
end
