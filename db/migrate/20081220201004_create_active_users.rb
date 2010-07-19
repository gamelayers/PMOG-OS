class CreateActiveUsers < ActiveRecord::Migration
  def self.up
    create_table :active_users do |t|
      t.integer :count
      t.date :date
    end

    add_index :active_users, [:date, :count]
    add_index :active_users, [:count, :date]
  end

  def self.down
    drop_table :active_users
  end
end
