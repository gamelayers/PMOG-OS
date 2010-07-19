class AddLevelToQuest < ActiveRecord::Migration
  def self.up
    add_column :quests, :level, :integer
  end

  def self.down
    remove_column :quests, :level
  end
end
