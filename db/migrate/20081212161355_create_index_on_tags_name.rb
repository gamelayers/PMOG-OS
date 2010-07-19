class CreateIndexOnTagsName < ActiveRecord::Migration
  def self.up
    add_index :tags, [:id, :name]
  end

  def self.down
    remove_index :tags, [:id, :name]
  end
end
