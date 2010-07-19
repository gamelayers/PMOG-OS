class AddNsfwColumnMissions < ActiveRecord::Migration
  def self.up
    add_column :missions, :nsfw, :boolean, :default => false
  end

  def self.down
    remove_column :missions, :nsfw
  end
end
