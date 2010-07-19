class AddBrowserEventsToEvents < ActiveRecord::Migration
  def self.up
    add_column :events, :browser, :integer, :limit => 1
    add_column :events, :read_at, :datetime
  end

  def self.down
    remove_column :events, :browser
    remove_column :events, :read_at
  end
end
