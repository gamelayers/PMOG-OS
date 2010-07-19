class Messages < ActiveRecord::Migration
  def self.up
    create_table :messages, :id => false do |t|
      t.column :id, :string, :limit => 36
      t.column :feed_id, :string, :limit => 36
      t.column :title, :string, :limit => 255, :null => false
      t.column :body, :text, :null => false
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
    end
    
    add_index :messages, :id
    add_index :messages, :feed_id
    add_index :messages, :created_at
  end

  def self.down
    drop_table :messages
  end
end