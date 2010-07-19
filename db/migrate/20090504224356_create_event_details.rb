class CreateEventDetails < ActiveRecord::Migration
  def self.up
    create_table :event_details do |t|
      t.string :event_id, :limit => 36
      t.string :body
      t.timestamps
    end

    add_index :event_details, :event_id

  end

  def self.down
    drop_table :event_details
  end
end
