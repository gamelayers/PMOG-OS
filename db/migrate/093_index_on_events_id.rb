class IndexOnEventsId < ActiveRecord::Migration
  def self.up
    add_index :events, :id
  end

  def self.down
    remove_index :events, :id
  end
end
