class CreateMissionStats < ActiveRecord::Migration
  def self.up
    create_table :mission_stats, :id => false do |t|
      t.string :id, :user_id, :mission_id, :limit => 36
      t.string :action
      t.string :context
      t.timestamps
    end

    add_index :mission_stats, [:context, :action, :created_at]
  end

  def self.down
    drop_table :mission_stats
  end
end
