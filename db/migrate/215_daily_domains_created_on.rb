# The daily domains table needs both created_at and created_on columns, so that we
# can avoid the use of aggregate functions like DATE() in the Badge queries that
# poll this table most often. This migration adds that extra column, and fills it
# with data too.
class DailyDomainsCreatedOn < ActiveRecord::Migration
  def self.up
    add_column :daily_domains, :week, :integer, :limit => 2
    add_column :daily_domains, :month, :integer, :limit => 2
    add_column :daily_domains, :year, :integer, :limit => 2
    add_column :daily_domains, :created_on, :date
    add_column :daily_domains, :updated_on, :date
    
    DailyDomain.execute( 'UPDATE daily_domains SET week = WEEK(updated_at), month = MONTH(updated_at), year = YEAR(updated_at), created_on = DATE(created_at), updated_on = DATE(updated_at)' )
    
    remove_column :daily_domains, :created_at
    remove_column :daily_domains, :updated_at
  end

  def self.down
    add_column :daily_domains, :created_at, :datetime
    add_column :daily_domains, :updated_at, :datetime
    
    DailyDomain.execute( 'UPDATE daily_domains SET created_at = created_on, updated_at = updated_on' )
    
    remove_column :daily_domains, :week
    remove_column :daily_domains, :month
    remove_column :daily_domains, :year
    remove_column :daily_domains, :created_on
    remove_column :daily_domains, :updated_on
  end
end
