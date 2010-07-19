class ConnectingBranchesToPortals < ActiveRecord::Migration
  def self.up
    add_column :portals, :branch_id, :string, :limit => 36
  end

  def self.down
    remove_column :portals, :branch_id
  end
end
