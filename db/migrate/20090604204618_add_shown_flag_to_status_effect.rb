class AddShownFlagToStatusEffect < ActiveRecord::Migration
  def self.up
    add_column :status_effects, :shown, :boolean, :default => false
  end

  def self.down
    remove_column :status_effects, :shown
  end
end
