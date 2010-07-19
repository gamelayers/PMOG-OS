class CreateEquippedItems < ActiveRecord::Migration
  def self.up
    create_table :equipped_items, :id => false do |t|
      t.column :id, :string, :limit => 36
      t.column :tool_id, :string, :limit => 36
      t.column :item_id, :string, :limit => 36
      t.column :charges, :integer
      t.column :equippable_id, :string, :limit => 36
      t.column :equippable_type, :string, :null => false
      t.timestamps 
    end
    
    add_index :equipped_items, :id
    add_index :equipped_items, :equippable_id
    add_index :equipped_items, :equippable_type
  end

  def self.down
    drop_table :equipped_items
  end
end
