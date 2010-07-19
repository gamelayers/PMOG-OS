class AddStealthCoulmnToCratesAndMines < ActiveRecord::Migration
  def self.up
    add_column :mines, :stealth, :boolean, :default => false
    add_column :crates, :stealth, :boolean, :default => false
  end

  def self.down
    remove_column :mines, :stealth
    remove_column :crates, :stealth
  end
end
