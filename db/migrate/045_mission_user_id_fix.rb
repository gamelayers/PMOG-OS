class MissionUserIdFix < ActiveRecord::Migration
  def self.up
    execute "ALTER TABLE missions CHANGE user_id user_id varchar(36) default NULL;"
  end

  def self.down
    execute "ALTER TABLE missions CHANGE user_id user_id varchar(255) default NULL;"
  end
end
