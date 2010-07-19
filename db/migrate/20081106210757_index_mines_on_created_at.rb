class IndexMinesOnCreatedAt < ActiveRecord::Migration
  def self.up
    add_index :mines, :created_at
  end

  def self.down
    remove_index :mines, :created_at
  end
end
