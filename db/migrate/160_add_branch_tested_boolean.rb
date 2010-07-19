class AddBranchTestedBoolean < ActiveRecord::Migration
  def self.up
    add_column :branches, :tested, :boolean, :default => false
  end

  def self.down
    remove_column :branches, :tested
  end
end
