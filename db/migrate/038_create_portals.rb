class CreatePortals < ActiveRecord::Migration
  def self.up
    create_table :portals, :id => false do |t|
      t.column :id, :string, :limit => 36
      t.column :user_id, :string, :limit => 36
      t.column :location_id, :string, :limit => 36
      t.column :destination_id, :string, :limit => 36
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
    end

    create_table :portals_users, :id => false do |t|
      t.column :portal_id, :string, :limit => 36
      t.column :user_id, :string, :limit => 36
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
    end

    add_index :portals, :id
    add_index :portals, :user_id
    add_index :portals, :location_id
    add_index :portals, :destination_id
  end

  def self.down
    drop_table :portals
    drop_table :portals_users
  end
end