class AlterInventoriesIndices < ActiveRecord::Migration
  def self.up
    remove_index :inventories, :tool_id
    remove_index :inventories, :item_id
    remove_index :inventories, :slottable_id
    remove_index :inventories, [ :slottable_id, :slottable_type ]
    
    # This was my attempt at a good index for this table, but EY suggested the one below, that we'll use instead
    #execute "CREATE INDEX idx_inventories_on_id_type_user_id ON inventories(slottable_id, slottable_type, tool_id)"
    execute "CREATE INDEX idx_inventories_on_slottable_id_created_at ON inventories(slottable_id, created_at)"
  end

  def self.down
    begin
      execute "DROP INDEX idx_inventories_on_slottable_id_created_at ON inventories"
      add_index :inventories, :tool_id
      add_index :inventories, :item_id
      add_index :inventories, :slottable_id
      add_index :inventories, [ :slottable_id, :slottable_type ]
    rescue
      puts "Failed to drop inventories index, most likey you're raking down after the RebuildInventoriesTable migration, which means this is ok."
    end
  end
end
