class CreateCrates < ActiveRecord::Migration
  def self.up
    create_table :crates, :id => false do |t|
      t.column :id, :string, :limit => 36
      t.column :user_id, :string, :limit => 36
      t.column :location_id, :string, :limit => 36
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
    end
    
    add_index :crates, :id
    add_index :crates, :user_id
    add_index :crates, :location_id
  end

  def self.down
    drop_table :crates
  end
end