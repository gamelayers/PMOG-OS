class InventoryWithChargesAndCrates < ActiveRecord::Migration
  def self.up
    remove_column :inventories, :instances
    add_column :inventories, :charges, :integer, :default => 0
    add_column :tools, :charges, :integer, :default => 0
    add_column :inventories, :crate_id, :string, :limit => 36
    
    # Default charges of 5 for both armor and portals
    tool = Tool.find_by_name( 'armor' )
    tool.charges = 5
    tool.save
    
    tool = Tool.find_by_name( 'portals' )
    tool.charges = 5
    tool.save
    
    tool = Tool.find_by_name( 'armor' )
    tool.charges = 3
    tool.save
  end

  def self.down
    begin
      add_column :inventories, :instances, :integer, :default => 0
      remove_column :inventories, :charges
      remove_column :tools, :charges
      remove_column :inventories, :crate_id
    rescue
      puts "Failed to drop inventories index, most likey you're raking down after the RebuildInventoriesTable migration, which means this is ok."
    end
  end
end