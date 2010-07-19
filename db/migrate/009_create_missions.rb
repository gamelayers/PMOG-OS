class CreateMissions < ActiveRecord::Migration
  def self.up
    create_table :missions, :id => false do |t|
      t.column :id, :string, :limit => 36
      t.column :name, :string, :limit => 255
      t.column :url_name, :string, :limit => 255
      t.column :description, :text, :null => false
      t.column :branches_count, :integer, :default => 0
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
    end
    
    add_index :missions, :id
    add_index :missions, :url_name
  end

  def self.down
    drop_table :missions
  end
end
