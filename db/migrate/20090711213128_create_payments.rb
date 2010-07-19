class CreatePayments < ActiveRecord::Migration
  def self.up
    create_table :payments do |t|
      t.timestamps
      t.integer :user_id, :null => false
      t.integer :action, :null => false
      t.references :item, :polymorphic => true
      t.decimal :amount, :precision => 8, :scale => 2, :null => false
      t.string :ip, :limit=>16
    end
  end

  def self.down
    drop_table :payments
  end
end
