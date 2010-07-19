class CreateDeletedAccounts < ActiveRecord::Migration
  def self.up
    create_table :deleted_accounts, :id => false do |t|
      t.string :id, :user_id, :deleted_id, :null => false, :limit => 36
      t.string :deleted_login
      t.string :user_ip
      t.timestamps
    end
  end

  def self.down
    drop_table :deleted_accounts
  end
end
