# == Schema Information
# Schema version: 20081220201004
#
# Table name: suspects
#
#  id          :string(36)    not null, primary key
#  user_id     :string(36)    not null
#  visits      :integer(11)   default(0), not null
#  remote_addr :string(255)   
#  timestamp   :datetime      
#  created_at  :datetime      
#  updated_at  :datetime      
#

# Suspects are users whom the track controller doesn't trust
class Suspect < ActiveRecord::Base
  belongs_to :user

  attr_accessible :user_id, :visits, :timestamp, :remote_addr

  def self.track( user, visits, timestamp, remote_addr )
    suspect_user = find( :first, :conditions => { :user_id=> user.id, :timestamp => timestamp, :remote_addr => remote_addr } )
    
    if suspect_user.nil?
      suspect_user = create( :user_id => user.id, :visits => visits, :timestamp => timestamp, :remote_addr => remote_addr )
    else
      suspect_user.visits = visits
      suspect_user.save
    end
    suspect_user
  end

  def before_create
    self.id = create_uuid
  end
end
