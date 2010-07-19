class ToolDamage < ActiveRecord::Migration
  def self.up
    add_column :tools, :damage, :integer, :default => 0
  end

  def self.down
    remove_column :tools, :damage
  end
end
