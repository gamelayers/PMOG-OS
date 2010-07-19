class CreateActsAsSubscribeableTables < ActiveRecord::Migration
  def self.up
    create_table :subscriptions, :id => false, :force => true do |t|
      t.string          :id, :user_id, :subscribeable_id, :null => false, :limit => 36
      t.string          :subscribeable_type
      t.timestamps
    end
  end

  def self.down
    drop_table :subscriptions
  end
end
