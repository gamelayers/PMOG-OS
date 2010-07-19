class AddCrateContext < ActiveRecord::Migration
  def self.up
    add_column :crates, :context, :string
  end

  def self.down
    remove_column :crates, :context
  end
end
