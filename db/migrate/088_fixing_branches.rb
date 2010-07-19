class FixingBranches < ActiveRecord::Migration
  def self.up
    execute "ALTER TABLE branches CHANGE id id VARCHAR(36) default NULL"
    execute "ALTER TABLE branches CHANGE mission_id mission_id VARCHAR(36) default NULL"
    execute "ALTER TABLE branches CHANGE parent_id parent_id VARCHAR(36) default NULL"

    # Quite a hack, I've no idea how things got so out of synch...
    b = Branch.new
    begin
      b.description
    rescue
      remove_column :branches, :name
      add_column :branches, :description, :text
    end
    
    # This is useful for Branch.nearby, and was added by EngineYard staff when we started
    # to slow down their databases during SXSW 2008
    execute "ALTER TABLE branches ADD INDEX idx_branches_mission_id_location_id (mission_id,location_id);"
  end

  def self.down
    execute "ALTER TABLE branches CHANGE id id int(11) default NULL"
    execute "ALTER TABLE branches CHANGE mission_id mission_id int(11) default NULL"
    execute "ALTER TABLE branches CHANGE parent_id parent_id int(11) default NULL"
  end
end
