class CreateBuddiesUsers < ActiveRecord::Migration
  def self.up
    create_table :buddies_users, :id => false do |t|
      t.column :buddy_id, :string, :limit => 36, :null => false
      t.column :user_id, :string, :limit => 36, :null => false
      t.column :type, :string, :limit => 255, :null => false
      t.column :accepted, :integer, :limit => 1, :default => 0
      t.column :requires_approval, :integer, :limit => 1, :default => 1
    end

    add_index :buddies_users, :buddy_id
    add_index :buddies_users, :user_id
    add_index :buddies_users, :type
    add_index :buddies_users, :accepted
    add_index :buddies_users, :requires_approval
  end

  def self.down
    drop_table :buddies_users
  end
end
