# == Schema Information
# Schema version: 20081220201004
#
# Table name: hourly_activities
#
#  id                :string(36)    not null, primary key
#  user_id           :string(36)    not null
#  extension_version :string(255)   not null
#  hour              :string(2)     not null
#  created_at        :datetime      
#  updated_at        :datetime      
#

class HourlyActivity < ActiveRecord::Base
  belongs_to :user

  acts_as_cached

  # Every active user will ping PMOG for messages. We can use that to create a 
  # metric of activity for registered users, which is what this does (as per DailyActivity).
  # Note also that we denormalise the hour instead of using HOUR() on the created_at date.
  # This should speed things up and allows us to not rely on MySQL specific functions.
  def self.record(user, version, date, hour)
    get_cache("recorder_#{user.login}_#{version}_#{date}_#{hour}") do
      today = Date.parse(date.to_s).to_s(:db)
      tomorrow = Date.parse(date.to_s).tomorrow.to_s(:db)
      previous = find( :first, :conditions => [ 'user_id = ? AND extension_version = ? AND created_at >= ? AND created_at < ? AND hour = ?', user.id, version, today, tomorrow, hour ] )
      create( :user_id => user.id, :extension_version => version, :created_at => Time.now, :hour => hour ) if previous.nil?
    end
  end

  def self.concurrent_users
    get_cache("concurrent_users") do
      HourlyActivity.find( :all, :select => 'count(distinct(user_id)) as total, DATE(created_at) as created_on, hour', :conditions => [ 'created_at > ?', 2.weeks.ago.to_s(:db) ], :group => 'DATE(created_at), hour')
    end
  end

  def self.wipe
    HourlyActivity.execute( 'truncate table hourly_activites' )
  end

  def before_create
    self.id = create_uuid
  end
end
