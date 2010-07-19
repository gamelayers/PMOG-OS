class ConvertHabtmBadgesToHasManyThrough < ActiveRecord::Migration
  def self.up
    execute "RENAME TABLE badges_users TO badgings"
  end

  def self.down
    execute "RENAME TABLE badgings TO badges_users"
  end
end
