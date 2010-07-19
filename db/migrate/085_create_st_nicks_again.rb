# Note that I b0rked this by committing a placeholder migration, back in 082.
# So we're dropping and creating on the way up, and dropping and creating on the way down.
class CreateStNicksAgain < ActiveRecord::Migration
  def self.up
    drop_table :st_nicks
    create_table :st_nicks, :id => false do |t|
      t.string :id, :limit => 36
      t.string :user_id, :limit => 36
      t.string :attachee_id, :limit => 36
      t.timestamps
    end
    
    add_index :st_nicks, :id
    add_index :st_nicks, :user_id
    add_index :st_nicks, :attachee_id
  end

  def self.down
    drop_table :st_nicks
    create_table :st_nicks do |t|
      t.timestamps
    end
  end
end