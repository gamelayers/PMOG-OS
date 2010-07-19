class ConvertHabtmPortalsToHasManyThrough < ActiveRecord::Migration
  def self.up
    execute "RENAME TABLE portals_users TO transportations"
  end

  def self.down
    execute "RENAME TABLE transportations TO portals_users"
  end
end
