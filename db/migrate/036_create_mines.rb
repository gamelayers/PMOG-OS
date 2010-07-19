class CreateMines < ActiveRecord::Migration
  def self.up
    create_table :mines, :id => false do |t|
      t.column :id, :string, :limit => 36
      t.column :user_id, :string, :limit => 36
      t.column :location_id, :string, :limit => 36
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
    end

    add_index :mines, :id
    add_index :mines, :user_id
    add_index :mines, :location_id
  end

  def self.down
    drop_table :mines
  end
end
