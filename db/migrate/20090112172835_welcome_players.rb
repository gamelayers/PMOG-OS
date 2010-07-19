class WelcomePlayers < ActiveRecord::Migration
  def self.up
    add_column :users, :welcomed, :boolean
  end

  def self.down
    remove_column :users, :welcomed
  end
end
