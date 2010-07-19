class AddToolsColumn < ActiveRecord::Migration
  def self.up
   # add_column :tools, :url_name, :string, :iimit=>255
  end

  def self.down
    remove_column :tools, :url_name
  end
end
