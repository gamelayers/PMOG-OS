class CreateEvents < ActiveRecord::Migration
  def self.up
    create_table :events, :id => false do |t|
      t.column :id, :string, :limit => 36
      t.column :user_id, :string, :limit => 36
      t.column :recipient_id, :string, :limit => 36
      t.column :message, :string, :null => false
      t.column :created_at, :datetime
    end
    add_index :events, :user_id
    add_index :events, :recipient_id
    add_index :events, :created_at
  end

  def self.down
    drop_table :events
  end
end
