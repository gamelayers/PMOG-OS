# These timestamp columns can help us 'version' the layouts table
# in memcached, which we'll definetly need.
class AddTimeStampsToLayouts < ActiveRecord::Migration
  def self.up
    add_column :layouts, :created_at, :datetime
    add_column :layouts, :updated_at, :datetime
  end

  def self.down
    remove_column :layouts, :created_at
    remove_column :layouts, :updated_at
  end
end
