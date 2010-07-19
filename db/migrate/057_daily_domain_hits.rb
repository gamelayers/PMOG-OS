class DailyDomainHits < ActiveRecord::Migration
  def self.up
    add_column :daily_domains, :hits, :integer, :default => 0
  end

  def self.down
    remove_column :daily_domains, :hits
  end
end
