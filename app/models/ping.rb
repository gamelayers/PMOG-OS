# == Schema Information
# Schema version: 20081220201004
#
# Table name: pings
#
#  id     :integer(11)   not null, primary key
#  name   :string(255)   
#  points :integer(11)   
#

# i deleted everything here because it was shitty and useless - alex 09-04-13
class Ping < ActiveRecord::Base

  acts_as_cached

  # mimic of GameSetting's .value
  def self.value(key)
    get_cache(key, :ttl => 1.week) do
      find(:first, :conditions => { :name => key.to_s }).points
    end
  end

end
