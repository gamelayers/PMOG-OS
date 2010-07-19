class BranchesCount < ActiveRecord::Migration
  def self.up
    add_column :branches, :branches_count, :integer, :default => 0
  end

  def self.down
    remove_column :branches, :branches_count
  end
end
