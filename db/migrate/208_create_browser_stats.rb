class CreateBrowserStats < ActiveRecord::Migration
  def self.up
    create_table :browser_stats, :id => false do |t|
      t.column :id, :string, :limit => 36, :null => false
      t.column :user_id, :string, :limit => 36, :null => false
      t.column :os, :string, :limit => 255, :null => false
      t.column :browser_name, :string, :limit => 255, :null => false
      t.column :browser_version, :string, :limit => 255, :null => false
      t.timestamps
    end

    add_index :browser_stats, :id
    add_index :browser_stats, [:os, :browser_name, :browser_version]
  end

  def self.down
    drop_table :browser_stats
  end
end
