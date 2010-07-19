class CreateDismissals < ActiveRecord::Migration
  def self.up
    create_table :dismissals, :id => false do |t|
      t.string :id, :limit => 36
      t.string :dismissable_type
      t.string :dismissable_id, :limit => 36
      t.string :user_id, :limit => 36
      t.timestamps
    end
    
    add_index :dismissals, :dismissable_type
    add_index :dismissals, :dismissable_id
  end

  def self.down
    drop_table :dismissals
  end
end
