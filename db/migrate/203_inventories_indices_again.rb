class InventoriesIndicesAgain < ActiveRecord::Migration
  def self.up
    execute "DROP INDEX idx_inventories_on_slottable_id_created_at ON inventories"
    execute "ALTER TABLE `inventories` ADD KEY idx_inventories_slottable_id_and_tool_id_and_slottable_type_etc (slottable_id,tool_id,slottable_type,created_at)"
  end

  def self.down
    begin
      execute "DROP INDEX idx_inventories_slottable_id_and_tool_id_and_slottable_type_etc ON inventories"
      execute "ALTER TABLE `inventories` ADD KEY idx_inventories_on_slottable_id_created_at(slottable_id, created_at)"
    rescue
      puts "Failed to drop inventories index, most likey you're raking down after the RebuildInventoriesTable migration, which means this is ok."
    end
  end
end
