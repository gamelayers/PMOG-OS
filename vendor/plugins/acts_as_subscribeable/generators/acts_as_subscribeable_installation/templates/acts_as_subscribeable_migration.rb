class CreateActsAsSubscribeableTables < ActiveRecord::Migration
  def self.up
    create_table :subscriptions, :force => true do |t|
      t.integer         :user_id
      t.integer         :subscribeable_id
      t.string          :subscribeable_type
      t.timestamps
    end
  end

  def self.down
    drop_table :subscriptions
  end
end
