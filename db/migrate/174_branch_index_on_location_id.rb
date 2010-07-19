# To speed up the Branch.nearby search for missions
class BranchIndexOnLocationId < ActiveRecord::Migration
  def self.up
    execute "CREATE INDEX `nearby` ON `branches` (`location_id`)"
  end

  def self.down
    execute "DROP INDEX `nearby` ON branches"
  end
end