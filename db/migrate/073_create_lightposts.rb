class CreateLightposts < ActiveRecord::Migration
  def self.up
    create_table :lightposts, :id => false do |t|
      t.string :id, :limit => 36
      t.string :user_id, :limit => 36
      t.string :locationid, :limit => 36
      t.timestamps 
    end
    
    add_index :lightposts, :id
    add_index :lightposts, :user_id
  end

  def self.down
    drop_table :lightposts
  end
end
