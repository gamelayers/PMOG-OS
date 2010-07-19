class CreateBranches < ActiveRecord::Migration
  def self.up
    create_table :branches, :id => false do |t|
      t.column :id, :string, :limit => 36
      t.column :mission_id, :string, :limit => 36
      t.column :parent_id, :string, :limit => 36
      t.column :description, :text, :null => false
      t.column :url, :text
      t.column :position, :integer, :null => false
    end
    
    create_table :branches_bird_bots, :id => false do |t|
      t.column :branch_id, :string, :limit => 36
      t.column :bird_bot_id, :string, :limit => 36
    end
    
    create_table :branches_npcs, :id => false do |t|
      t.column :branch_id, :string, :limit => 36
      t.column :npc_id, :string, :limit => 36
    end
    
    add_index :branches, :id
    add_index :branches, :mission_id
    add_index :branches, :parent_id
    
    add_index :branches_bird_bots, :branch_id
    add_index :branches_bird_bots, :bird_bot_id
    
    add_index :branches_npcs, :branch_id
    add_index :branches_npcs, :npc_id
  end

  def self.down
    drop_table :branches
    drop_table :branches_bird_bots
    drop_table :branches_npcs
  end
end