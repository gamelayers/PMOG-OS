class CreateForums < ActiveRecord::Migration
  def self.up
    create_table :forums, :id => false do |t|
      t.column :id, :string, :limit => 36
      t.column :title, :string
      t.column :description, :text
      t.column :url_name, :string, :limit => 255
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
    end
    
    add_index :forums, :id
    add_index :forums, :url_name
  end

  def self.down
    drop_table :forums
  end
end
