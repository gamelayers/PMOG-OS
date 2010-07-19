class TldBigInt < ActiveRecord::Migration
  def self.up
    execute "alter table tlds change column total total bigint default 0"
  end

  def self.down
  end
end
