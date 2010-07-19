class MissionFix < ActiveRecord::Migration
  def self.up
    execute "ALTER TABLE missions CHANGE id id VARCHAR(36) default NULL"
  end

  def self.down
    # n/a
  end
end
