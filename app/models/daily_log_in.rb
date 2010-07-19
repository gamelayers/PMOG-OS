# == Schema Information
# Schema version: 20081220201004
#
# Table name: daily_log_ins
#
#  id         :string(36)    primary key
#  user_id    :string(36)    
#  created_at :datetime      
#  updated_at :datetime      
#

# Record each time the user comes back to the site
class DailyLogIn < ActiveRecord::Base

  validates_presence_of :user_id

  def self.wipe
    DailyDomain.execute( "delete from daily_log_ins where created_at < '#{2.months.ago.to_s(:db)}'")
  end

  def before_create
    self.id = create_uuid
  end
end
