class CreatePreferences < ActiveRecord::Migration
  def self.up
    create_table :preferences, :id => false do |t|
      t.string :id, :limit => 36
      t.string :user_id, :limit => 36
      t.string :name, :limit => 255, :null => false
      t.string :value, :limit => 255, :null => false
      t.timestamps
    end
    
    add_index :preferences, :id
    add_index :preferences, :user_id
  end

  def self.down
    drop_table :preferences
  end
end
