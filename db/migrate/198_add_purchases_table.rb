class AddPurchasesTable < ActiveRecord::Migration
  def self.up
    create_table :purchases, :force => true do |t|
      t.string :tool_id, :limit => 36
      t.string :user_id, :limit => 36
      t.integer :quantity
      t.integer :totalprice, :null => true
      t.timestamps
    end
  end
  
  def self.down
    drop_table :purchases
  end
end
