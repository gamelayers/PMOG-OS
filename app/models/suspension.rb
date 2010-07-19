# == Schema Information
# Schema version: 20081220201004
#
# Table name: suspensions
#
#  id         :string(36)    not null, primary key
#  user_id    :string(36)    not null
#  admin_id   :string(36)    not null
#  reason     :text          
#  created_at :datetime      
#  updated_at :datetime      
#  expires_at :datetime      
#

class Suspension < ActiveRecord::Base
  
  # So we can use the distance_of_time_in_words in our event
  require 'lib/helpers'
  
  belongs_to :user, :class_name => "User", :foreign_key => "user_id"
  belongs_to :admin, :class_name => "User", :foreign_key => "admin_id"

  validates_presence_of :user_id, :on => :create, :message => "can't be blank"
  validates_presence_of :admin_id, :on => :create, :message => "can't be blank"
  validates_presence_of :expires_at, :on => :create, :message => "can't be blank"
  
  after_create  :suspended_event
  before_update :restore_event

  # Generate the UUID for the object
  def before_create
    self.id = create_uuid
  end

  # This is a delegated method for the user class to determine if the user is suspended
  class << self
    def suspended?
      suspensions = find( :all, :conditions => [ 'expires_at IS NOT NULL AND expires_at > ?', Time.now.to_s(:db) ] )
      not suspensions.empty?
    end
    
    def suspended_until
      last_suspension = find(:first, :order => 'expires_at DESC');
      return last_suspension.expires_at
    end
    
    def suspended_on
      last_suspension = find(:first, :order => 'expires_at DESC');
      return last_suspension.created_at
    end
    
    def suspended_reason
      the_reason = nil
      last_suspension = find(:first, :order => 'expires_at DESC');
        if last_suspension.reason.nil? or last_suspension.reason.empty?
          the_reason = "No record"
        else
          the_reason = last_suspension.reason
        end
      return the_reason
    end
    
  end

  private
  
  def suspended_event
    Event.record :user_id => self.user_id, 
      :context => 'user_suspended',
      :message => "was just suspended for #{help.distance_of_time_in_words(Time.now, self.expires_at) }"
  end
  
  def restore_event
    if self.expires_at.before? Time.now
      Event.record :user_id => self.user_id,
        :context => 'user_pardoned',
        :message => "was just pardoned from being suspended!"
    end
  end

end
