class CreateUnsubscribeRequests < ActiveRecord::Migration
  def self.up
    create_table :unsubscribe_requests, :id => false do |t|
      t.string :id, :limit => 36
      t.string :user_id, :limit => 36
      t.boolean :confirmed, :default => false
      t.timestamps
    end
    
    add_index :unsubscribe_requests, :id
    add_index :unsubscribe_requests, :user_id
  end

  def self.down
    drop_table :unsubscribe_requests
  end
end
