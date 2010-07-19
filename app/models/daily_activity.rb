# == Schema Information
# Schema version: 20081220201004
#
# Table name: daily_activities
#
#  id                :string(36)    not null, primary key
#  user_id           :string(36)    not null
#  extension_version :string(255)   not null
#  created_on        :string(255)   not null
#

class DailyActivity < ActiveRecord::Base
  belongs_to :user

  # Every active user will ping PMOG for messages. We can use that to 
  # create a metric of activity for registered users, which is what this does
  def self.record(user, version, date)
    unless find( :first, :conditions => { :user_id => user.id, :extension_version => version, :created_on => date } )
      create( :user_id => user.id, :extension_version => version, :created_on => date )
    end
  end
  
  def before_create
    self.id = create_uuid
  end
end
