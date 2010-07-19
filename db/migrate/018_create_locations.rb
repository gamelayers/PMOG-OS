class CreateLocations < ActiveRecord::Migration
  def self.up
    create_table :locations, :id => false do |t|
      t.column :id, :string, :limit => 36
      t.column :url, :string
    end

    add_index :locations, :id
    add_index :locations, :url
  end

  def self.down
    drop_table :locations
  end
end