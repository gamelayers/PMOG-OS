class CreateTools < ActiveRecord::Migration
  def self.up
    create_table :tools do |t|
      t.column :name, :string, :null => false
      t.column :description, :text, :null => false
      t.column :cost, :int, :null => false, :default => 0
      t.column :character, :string, :null => false
    end

    create_table :inventories, :id => false do |t|
      t.column :id, :string, :limit => 36
      t.column :user_id, :string, :limit => 36, :null => false
      t.column :tool_id, :integer, :null => false
      t.column :total, :integer, :null => false, :default => 0
    end

    add_index :tools, :name
    add_index :tools, :character
    add_index :inventories, :id
    add_index :inventories, :user_id
    add_index :inventories, :tool_id
  end

  def self.down
    drop_table :tools
    drop_table :inventories
  end
end