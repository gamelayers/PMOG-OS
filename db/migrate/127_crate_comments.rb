class CrateComments < ActiveRecord::Migration
  def self.up
    add_column :crates, :comments, :string, :limit => 255, :default => nil
  end

  def self.down
    remove_column :crates, :comments
  end
end
