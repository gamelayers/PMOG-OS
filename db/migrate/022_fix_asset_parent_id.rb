class FixAssetParentId < ActiveRecord::Migration
  def self.up
    execute "ALTER TABLE assets CHANGE parent_id parent_id VARCHAR(36) default NULL"
  end

  def self.down
    execute "ALTER TABLE assets CHANGE parent_id parent_id INT(11) default NULL"
  end
end
