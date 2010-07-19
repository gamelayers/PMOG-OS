class CreateFaves < ActiveRecord::Migration
  def self.up
    create_table :faves, :id => false do |t|
      t.string :id, :limit => 36
      t.string :user_id, :limit => 36
      t.string :location_id, :limit => 36
      t.timestamps 
    end
    
    add_index :faves, :id
    add_index :faves, :user_id
  end

  def self.down
    drop_table :faves
  end
end
