# == Schema Information
# Schema version: 20081220201004
#
# Table name: browser_stats
#
#  id              :string(36)    not null, primary key
#  user_id         :string(36)    not null
#  os              :string(255)   not null
#  browser_name    :string(255)   not null
#  browser_version :string(255)   not null
#  created_at      :datetime      
#  updated_at      :datetime      
#

# For tracking user browser stats - OS, Version, etc
class BrowserStat < ActiveRecord::Base
  def before_create
    self.id = create_uuid
  end
end
