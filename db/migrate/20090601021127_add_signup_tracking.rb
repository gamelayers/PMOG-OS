class AddSignupTracking < ActiveRecord::Migration
  def self.up
    add_column :users, :signup_source, :string
    add_column :users, :signup_version, :string
  end

  def self.down
    remove_column :users, :signup_version
    remove_column :users, :signup_source
  end
end
