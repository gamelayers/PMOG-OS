class AddUrlNameToQuest < ActiveRecord::Migration
  def self.up
    add_column :quests, :url_name, :string
  end

  def self.down
    remove_column :quests, :url_name
  end
end
