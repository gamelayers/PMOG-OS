class AddDeletedAtColumnForumtopics < ActiveRecord::Migration
  def self.up
        add_column :topics, :deleted_at, :datetime
  end

  def self.down
    remove_column :topics, :deleted_at
  end
end
