class AddPaycheckAtToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :paycheck_at, :datetime
  end

  def self.down
    remove_column :users, :paycheck_at
  end
end
