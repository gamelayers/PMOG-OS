class ActsAsReadableMigration < ActiveRecord::Migration
  def self.up
    create_table :readings do |t|
      t.string :readable_type
      t.string :readable_id, :limit => 36
      t.string :user_id, :limit => 36
      t.timestamps
    end
  end

  def self.down
    drop_table :readings
  end
end
