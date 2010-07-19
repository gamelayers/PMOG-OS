class CreateQueuedMissions < ActiveRecord::Migration
  def self.up
    drop_table :hoards
    create_table :queued_missions, :id => false do |t|
      t.string :id, :user_id, :mission_id, :null => false, :limit => 36
      t.timestamps
    end
  end

  def self.down
    drop_table :queued_missions

    create_table :hoards, :id => false do |t|
      t.string :id, :user_id, :mission_id, :null => false, :limit => 36
      t.timestamps
    end
  end
end
