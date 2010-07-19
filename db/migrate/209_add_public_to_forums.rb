class AddPublicToForums < ActiveRecord::Migration
  def self.up
    add_column :forums, :public, :boolean, :default => true
  end

  def self.down
    remove_column :forums, :public
  end
end
