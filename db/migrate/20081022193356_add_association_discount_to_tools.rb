class AddAssociationDiscountToTools < ActiveRecord::Migration
  def self.up
    add_column :tools, :association_cost, :integer, :limit => 11, :default => 0, :null => false
  end

  def self.down
    remove_column :tools, :association_cost
  end
end
