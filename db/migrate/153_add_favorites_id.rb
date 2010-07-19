class AddFavoritesId < ActiveRecord::Migration
  def self.up
    add_column :favorites, :id, :string, :limit => 36
    add_index :favorites, :id
  end

  def self.down
    remove_index :favorites, :column => :id
    remove_column :favorites, :id
  end
end
