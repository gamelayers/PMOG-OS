class CreateRatings < ActiveRecord::Migration
  def self.up
    create_table :ratings, :id => false do |t|
      t.column :id, :string, :limit => 36
      t.column :score, :integer, :default => 0
      t.column :rateable_type, :string
      t.column :rateable_id, :string, :limit => 36
      t.column :user_id, :string, :limit => 36
      t.column :updated_at, :datetime
      t.column :created_at, :datetime
    end
    
    add_index :ratings, :rateable_type
    add_index :ratings, :rateable_id
  end

  def self.down
    drop_table :ratings
  end
end