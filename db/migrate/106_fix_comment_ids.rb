class FixCommentIds < ActiveRecord::Migration
  def self.up
    change_column :comments, :commentable_id, :string, :limit => 36, :null => false
    change_column :comments, :user_id, :string, :limit => 36, :null => false
  end

  def self.down
  end
end
