class CreateGoals < ActiveRecord::Migration
  def self.up
    create_table :goals, :id => false do |t|
      t.string :id, :quest_id, :tool_id, :location_id, :user_id, :action_id, :limit => 36
      t.string :description
      t.integer :count
      t.timestamps
    end
  end

  def self.down
    drop_table :goals
  end
end
