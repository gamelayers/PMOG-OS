class CreateRewards < ActiveRecord::Migration
  def self.up
    create_table :rewards, :id => false do |t|
      t.string :id, :rewardable_id, :tool_id, :limit => 36
      t.integer :datapoints, :pings, :amount
      t.timestamps
    end
  end

  def self.down
    drop_table :rewards
  end
end
