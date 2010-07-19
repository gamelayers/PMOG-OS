class CreateReactiveUsers < ActiveRecord::Migration
  def self.up
    create_table :reactive_users do |t|
      t.integer :count
      t.date :date
    end

    add_index :reactive_users, [:date, :count]
    add_index :reactive_users, [:count, :date]
  end

  def self.down
    drop_table :reactive_users
  end
end
