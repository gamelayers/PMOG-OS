class UserMessages < ActiveRecord::Migration
  def self.up
    add_column :messages, :user_id, :string, :limit => 36
    add_column :messages, :recipient_id, :string, :limit => 36
    add_column :messages, :read_at, :datetime
    
    add_index :messages, :user_id
    add_index :messages, :recipient_id
    
    execute "ALTER TABLE messages CHANGE title title VARCHAR(255) default NULL"
  end

  def self.down
    remove_column :messages, :user_id
    remove_column :messages, :recipient_id
    remove_column :messages, :read_at

    execute "ALTER TABLE messages CHANGE title title VARCHAR(255) NOT NULL"
  end
end
