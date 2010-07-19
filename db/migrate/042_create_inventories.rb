class CreateInventories < ActiveRecord::Migration
  def self.up
    drop_table :inventories

    create_table :inventories, :id => false do |t|
      t.column :id, :string, :limit => 36
      t.column :user_id, :string, :limit => 36
      t.column :tool_id, :string, :limit => 36
      t.column :item_id, :string, :limit => 36
      t.column :instances, :integer
      t.column :datapoints, :integer
      t.column :slottable_id, :string, :limit => 36
      t.column :slottable_type, :string, :null => false
      t.timestamps
    end
    
    create_table :inventories_tools, :id => false do |t|
      t.column :inventory_id, :string, :limit => 36
      t.column :tool_id, :string, :limit => 36
    end
    
    create_table :inventories_items, :id => false do |t|
      t.column :item_id, :string, :limit => 36
      t.column :inventory_id, :string, :limit => 36
    end
    
    add_index :inventories, :id
    add_index :inventories, :user_id
    add_index :inventories, :tool_id
    add_index :inventories, :item_id
    add_index :inventories, :slottable_id

    add_index :inventories_tools, :inventory_id
    add_index :inventories_tools, :tool_id

    add_index :inventories_items, :item_id
    add_index :inventories_items, :inventory_id
  end

  def self.down
    drop_table :inventories
    drop_table :inventories_tools
    drop_table :inventories_items
    
    create_table :inventories, :id => false do |t|
      t.column :id, :string, :limit => 36
      t.column :user_id, :string, :limit => 36, :null => false
      t.column :tool_id, :integer, :null => false
      t.column :total, :integer, :null => false, :default => 0
    end
  end
end