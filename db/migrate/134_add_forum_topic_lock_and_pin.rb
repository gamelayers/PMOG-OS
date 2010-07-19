class AddForumTopicLockAndPin < ActiveRecord::Migration
  def self.up
    add_column :topics, :locked, :boolean, :default => false
    add_column :topics, :pinned, :boolean, :default => false
  end

  def self.down
    remove_column :topics, :locked
    remove_column :topics, :pinned
  end
end
