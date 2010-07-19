class ChangeMissionDatatype < ActiveRecord::Migration
  def self.up
        change_column :comments, :comment, :text
  end

  def self.down
  end
end
