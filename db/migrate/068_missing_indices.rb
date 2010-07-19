class MissingIndices < ActiveRecord::Migration
  def self.up
    add_index :assets, [ :attachable_id, :attachable_type ]
    add_index :inventories, [ :slottable_id, :slottable_type ]
    add_index :equipped_items, [ :equippable_id, :equippable_type ]
    add_index :beta_users, :email
    add_index :beta_users, :beta_key_id
    add_index :users, :beta_key_id
    add_index :missions, :user_id
    add_index :tags, :id
  end

  def self.down
    #remove_index :assets, [ :attachable_id, :attachable_type ]
    remove_index :equipped_items, [ :equippable_id, :equippable_type ]
    remove_index :beta_users, :email
    remove_index :beta_users, :beta_key_id
    remove_index :users, :beta_key_id
    remove_index :missions, :user_id
    remove_index :tags, :id
    
    begin
      remove_index :inventories, [ :slottable_id, :slottable_type ]
    rescue
      puts "Failed to drop inventories index, most likey you're raking down after the RebuildInventoriesTable migration, which means this is ok."
    end
  end
end