class LengthenLogin < ActiveRecord::Migration
  def self.up
    execute "alter table users change column login login varchar(40) not null"
  end

  def self.down
  end
end
