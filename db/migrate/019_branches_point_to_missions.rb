class BranchesPointToMissions < ActiveRecord::Migration
  def self.up
    create_table :branches_missions, :id => false do |t|
      t.column :branch_id, :string, :limit => 36
      t.column :mission_id, :string, :limit => 36
    end
    
    add_index :branches_missions, :branch_id
    add_index :branches_missions, :mission_id
  end

  def self.down
    drop_table :branches_missions
  end
end
