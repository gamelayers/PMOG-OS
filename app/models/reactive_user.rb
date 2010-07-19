# == Schema Information
# Schema version: 20081220201004
#
# Table name: reactive_users
#
#  id    :integer(11)   not null, primary key
#  count :integer(11)   
#  date  :date          
#

# Primarily for use in conjustion with the Stat.calculate_active_users graph
class ReactiveUser < ActiveRecord::Base
  # Returns the latest +date+ from the reactive_users table
  def self.latest_date
    latest = find(:first, :order => 'date DESC')
    latest.nil? ? '' : latest.date.end_of_day
  end
  
  # Returns the number of users reacting for each day PMOG has been running
  # - excludes today's data since it won't be an accurate figure
  def self.data_for_graph
    find(:all, :conditions => ['date != ?', Date.today], :order => 'date ASC')
  end
end
