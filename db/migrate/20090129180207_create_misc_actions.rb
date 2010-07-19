class CreateMiscActions < ActiveRecord::Migration
  def self.up
    create_table :misc_actions, :id => false, :force => true do |t|
      #GENERIC FIELDS
      t.string :id, :limit => 36
      t.string :name
      t.string :url_name
      t.string :association_id, :limit => 36
      t.integer :level, :limit => 11
      t.string :short_description
      t.string :icon_image
      t.string :small_image
      t.string :medium_image
      t.string :large_image
      t.text :long_description
      t.text :history
      #MISC FIELDS
      t.integer :cost, :limit => 11
      t.integer :value, :limit => 11, :default => 0
      t.integer :misc, :limit => 11
			t.integer :classpoints, :limit => 11
      t.timestamps
    end
  end

  def self.down
    drop_table :misc_actions
  end
end
