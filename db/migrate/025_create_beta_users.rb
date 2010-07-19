class CreateBetaUsers < ActiveRecord::Migration
  def self.up
    create_table :beta_users do |t|
      t.column :email, :string, :limit => 255
      t.column :emailed, :int, :default => 0, :limit => 1
    end
  end

  def self.down
    drop_table :beta_users
  end
end