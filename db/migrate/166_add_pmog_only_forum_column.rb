class AddPmogOnlyForumColumn < ActiveRecord::Migration
  def self.up
    add_column :forums, :pmog_only, :boolean, :null => false, :default => false
  end

  def self.down
    remove_column :forums, :pmog_only
  end
end
