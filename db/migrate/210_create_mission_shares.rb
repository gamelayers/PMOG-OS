class CreateMissionShares < ActiveRecord::Migration
  def self.up
    create_table :mission_shares, :id => false, :force => true do |t|
      t.string :id, :limit => 36
      t.string :sender_id, :limit => 36
      t.integer :mission_id
      t.string :recipient
      t.integer :reward, :default => 0
      t.boolean :fulfilled, :default => false
      t.timestamps
    end
  end

  def self.down
    drop_table :mission_shares
  end
end
