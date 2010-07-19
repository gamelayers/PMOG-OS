class CreateImages < ActiveRecord::Migration
  def self.up
    create_table :images, :id => false do |t|
      t.column :id, :string, :limit => 36
      t.column :filename, :string
      t.column :width, :integer
      t.column :height, :integer
      t.column :content_type, :string
      t.column :size, :integer
      t.column :attachable_type, :string
      t.column :attachable_id, :string, :limit => 36
      t.column :updated_at, :datetime
      t.column :created_at, :datetime
      t.column :thumbnail, :string
      t.column :parent_id, :integer
    end

    add_index :images, :id
    add_index :images, :parent_id
  end

  def self.down
    drop_table :images
  end
end
