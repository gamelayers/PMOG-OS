class InventoriesIndex < ActiveRecord::Migration
  def self.up
    execute "ALTER TABLE inventories ADD INDEX idx_inventories_on_slottable_id_slottable_type_tool_id (slottable_id,slottable_type,tool_id)"
  end

  def self.down
    begin
      execute "DROP INDEX idx_inventories_on_slottable_id_slottable_type_tool_id ON inventories"
    rescue
      puts "Failed to drop inventories index, most likey you're raking down after the RebuildInventoriesTable migration, which means this is ok."
    end
  end
end
