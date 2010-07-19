class CreateMotd < ActiveRecord::Migration
  def self.up
    create_table :motd, :id => false do |t|
      t.string :id, :limit => 36, :null => false
      t.string :title, :limit => 255, :default => nil
      t.text :body, :null => false
      t.timestamps
    end
    
    add_index :motd, :created_at
  end

  def self.down
    drop_table :motd
  end
end
