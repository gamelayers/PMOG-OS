class MissionUsers < ActiveRecord::Migration
  def self.up
    create_table :missions_users, :id => false do |t|
      t.column :mission_id, :string, :limit => 36
      t.column :user_id, :string, :limit => 36
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
    end

    add_index :missions_users, :user_id
    add_index :missions_users, :mission_id

    # oops, forgot these earlier...
    add_index :portals_users, :user_id
    add_index :portals_users, :portal_id
  end

  def self.down
    drop_table :missions_users
    remove_index :portals_users, :portal_id
    remove_index :portals_users, :user_id
  end
end
