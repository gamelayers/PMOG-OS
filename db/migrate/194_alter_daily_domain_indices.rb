class AlterDailyDomainIndices < ActiveRecord::Migration
  def self.up
    remove_index :daily_domains, :user_id
    remove_index :daily_domains, :location_id
    execute "CREATE INDEX idx_daily_domains_on_user_id_location_id_created_at ON daily_domains(user_id, location_id, created_at)"
  end

  def self.down
    execute "DROP INDEX idx_daily_domains_on_user_id_location_id_created_at ON daily_domains"
    add_index :daily_domains, :user_id
    add_index :daily_domains, :location_id
  end
end
