class CreateTlds < ActiveRecord::Migration
  def self.up
    create_table :tlds do |t|
      t.timestamps
      t.string :name, :limit => 255, :null => false
      t.integer :total, :default => 0
      t.string :last_ip, :limit => 15 # xxx.xxx.xxx.xxx
      t.integer :user_id # last user to be on site
    end

    execute "alter table tlds change column total total bigint"

    add_index :tlds, :name, :unique=>true
    add_index :tlds, [:name, :total]
    add_index :tlds, :user_id
  end

  def self.down
    drop_table :tlds
  end
end
