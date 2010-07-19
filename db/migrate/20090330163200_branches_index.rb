class BranchesIndex < ActiveRecord::Migration
  def self.up
    add_index :branches, [:parent_id, :position]
  end

  def self.down
    remove_index :branches, [:parent_id, :position]
  end
end
