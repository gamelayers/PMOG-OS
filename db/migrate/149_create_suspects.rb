class CreateSuspects < ActiveRecord::Migration
  def self.up
    create_table :suspects, :id => false do |t|
      t.string :id, :limit => 36, :null => false
      t.string :user_id, :limit => 36, :null => false
      t.integer :visits, :default => 0, :null => false
      t.string :remote_addr
      t.timestamp :timestamp
      t.timestamps
    end
    
    add_index :suspects, :id
    add_index :suspects, :user_id
  end

  def self.down
    drop_table :suspects
  end
end
