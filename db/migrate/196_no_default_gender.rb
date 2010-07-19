class NoDefaultGender < ActiveRecord::Migration
  def self.up
    execute "ALTER TABLE users MODIFY gender varchar(1) DEFAULT NULL"
  end

  def self.down
    execute "ALTER TABLE users MODIFY gender varchar(1) DEFAULT 'm'"
  end
end
