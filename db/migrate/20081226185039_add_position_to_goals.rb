class AddPositionToGoals < ActiveRecord::Migration
  def self.up
    add_column :goals, :position, :integer
  end

  def self.down
    remove_column :goals, :position
  end
end
