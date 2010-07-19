class ActsAsTaggableMigration < ActiveRecord::Migration
  def self.up
    drop_table :taggings
    drop_table :tags
    
    create_table :tags, :id => false do |t|
      t.string :id, :limit => 36, :null => false
      t.string :name
    end
    
    create_table :taggings, :id => false do |t|
      t.string :id, :limit => 36, :null => false
      t.string :tag_id, :limit => 36, :null => false
      t.string :taggable_id, :limit => 36, :null => false
      
      # You should make sure that the column created is
      # long enough to store the required class names.
      t.string :taggable_type
      
      t.timestamps
    end
    
    add_index :taggings, :tag_id
    add_index :taggings, [:taggable_id, :taggable_type]
  end
  
  def self.down
    drop_table :taggings
    drop_table :tags

    create_table :tags, :id => false do |t|
      t.column :id, :string, :limit => 36
      t.column :name, :string
      t.column :taggings_count, :integer, :default => 0, :null => false
      t.timestamps
    end

    add_index :tags, :name
    add_index :tags, :taggings_count
    add_index :tags, :id

    create_table :taggings, :id => false do |t|
      t.column :id, :string, :limit => 36
      t.column :tag_id, :string, :limit => 36
      t.column :taggable_id, :string, :limit => 36
      t.column :taggable_type, :string
      t.column :user_id, :string, :limit => 36
    end

    # Find objects for a tag
    add_index :taggings, [:tag_id, :taggable_type]
    add_index :taggings, [:user_id, :tag_id, :taggable_type]
    # Find tags for an object 
    add_index :taggings, [:taggable_id, :taggable_type]
    add_index :taggings, [:user_id, :taggable_id, :taggable_type]


  end
end
