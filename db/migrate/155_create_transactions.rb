class CreateTransactions < ActiveRecord::Migration
  def self.up
    create_table :transactions, :id => false do |t|
      t.string  :id, :user_id, :action, :item, :limit => 36
      t.integer :amount
      t.text :comment
      t.timestamps
    end
  end

  def self.down
    drop_table :transactions
  end
end