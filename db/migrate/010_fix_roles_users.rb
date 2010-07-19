class FixRolesUsers < ActiveRecord::Migration
  def self.up
    drop_table :roles_users

    create_table :roles_users, :force => true, :id => false  do |t|
      t.column :user_id,          :string, :login => 36
      t.column :role_id,          :integer
      t.column :created_at,       :datetime
      t.column :updated_at,       :datetime
    end
    
    add_index :roles_users, :user_id
    add_index :roles_users, :role_id
    
    # Add a default user and site_admin role (again)
    insert( "INSERT INTO roles_users (user_id, role_id, created_at, updated_at) VALUES ('d780f502-5a13-11dc-a067-0017f232d58f', 1, NOW(), NOW());" )
  end

  def self.down
    drop_table :roles_users

    create_table :roles_users, :force => true  do |t|
      t.column :user_id,          :string, :login => 36
      t.column :role_id,          :integer
      t.column :created_at,       :datetime
      t.column :updated_at,       :datetime
    end

    add_index :roles_users, :user_id
    add_index :roles_users, :role_id
    
    # Add a default user and site_admin role (again)
    insert( "INSERT INTO roles_users (user_id, role_id, created_at, updated_at) VALUES ('d780f502-5a13-11dc-a067-0017f232d58f', 1, NOW(), NOW());" )
  end
end
