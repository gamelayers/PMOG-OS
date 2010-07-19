class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table "users", :force => true, :id => false do |t|
      t.column :id, :string, :limit => 36
      t.column :login, :string
      t.column :email, :string
      t.column :crypted_password, :string, :limit => 40
      t.column :salt, :string, :limit => 40
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
      t.column :last_login_at, :datetime
      t.column :remember_token, :string
      t.column :remember_token_expires_at, :datetime
      t.column :visits_count, :integer, :default => 0
      t.column :time_zone, :string, :default => 'Etc/UTC'
    end
    
    add_index :users, :id
    add_index :users, :login
    add_index :users, :email
    add_index :users, :updated_at
    add_index :users, :remember_token
  end

  def self.down
    drop_table "users"
  end
end
