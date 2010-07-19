class CreateRoles < ActiveRecord::Migration
  def self.up
    create_table :roles_users, :force => true  do |t|
      t.column :user_id,          :string, :login => 36
      t.column :role_id,          :integer
      t.column :created_at,       :datetime
      t.column :updated_at,       :datetime
    end

    create_table :roles, :force => true do |t|
      t.column :name,               :string, :limit => 40
      t.column :authorizable_type,  :string, :limit => 30
      t.column :authorizable_id,    :integer
      t.column :created_at,         :datetime
      t.column :updated_at,         :datetime
    end
    
    add_index :roles, :name
    add_index :roles_users, :user_id
    add_index :roles_users, :role_id
    
    # Add a default user and site_admin role
    insert( "INSERT INTO `users` VALUES ('d780f502-5a13-11dc-a067-0017f232d58f','suttree','duncan@suttree.com','0d20f47327b2d3c43e66aaef0bf4e6e1baab3ec4','e105c04b449fe0fa8883ec45fa7d56c7194d6011','2007-09-03 11:50:18','2007-09-03 11:50:18',NULL,NULL,NULL,0,'Etc/Greenwich','http://www.suttree.com/');" )
    insert( "INSERT INTO roles (id, name, created_at, updated_at) VALUES (1, 'site_admin', NOW(), NOW() ); ")
    insert( "INSERT INTO roles_users (user_id, role_id, created_at, updated_at) VALUES ('d780f502-5a13-11dc-a067-0017f232d58f', 1, NOW(), NOW());" )
  end

  def self.down
    drop_table :roles
    drop_table :roles_users
  end
end

class User
  def url
    'http://www.migration005.com'
  end
end