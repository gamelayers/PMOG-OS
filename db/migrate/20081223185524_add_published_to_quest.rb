class AddPublishedToQuest < ActiveRecord::Migration
  def self.up
    add_column :quests, :published, :boolean, :default => false
  end

  def self.down
    remove_column :quests, :published
  end
end
