class UserFields < ActiveRecord::Migration
  def self.up
    add_column :users, :forename, :string, :limit => 255
    add_column :users, :surname, :string, :limit => 255
    add_column :users, :url, :string, :limit => 255
    add_column :users, :date_of_birth, :date
    add_column :users, :gender, :string, :limit => 1, :default => 'm'
    add_column :users, :country, :string, :limit => 255
  end

  def self.down
    remove_column :users, :forename
    remove_column :users, :surname
    remove_column :users, :url
    remove_column :users, :date_of_birth
    remove_column :users, :gender
    remove_column :users, :country
  end
end
