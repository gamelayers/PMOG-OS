class AllowNullPositionValue < ActiveRecord::Migration
  def self.up
    change_column :branches, :position, :integer, :null => true
  end

  def self.down
    change_column :branches, :position, :integer, :null => false
  end
end
