class BranchCompoundIndex < ActiveRecord::Migration
  def self.up
    execute "create index idx_branches_mission_id_location_id_position on branches (mission_id, location_id, position)"
  end

  def self.down
    execute "drop index idx_branches_mission_id_location_id_position on branches"
  end
end
