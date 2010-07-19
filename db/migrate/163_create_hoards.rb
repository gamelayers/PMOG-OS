class CreateHoards < ActiveRecord::Migration
  def self.up
    create_table :hoards, :id => false do |t|
      t.string :id, :user_id, :mission_id, :null => false, :limit => 36
      t.timestamps
    end
  end

  def self.down
    drop_table :hoards
  end
end
