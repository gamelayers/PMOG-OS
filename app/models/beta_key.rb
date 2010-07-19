# == Schema Information
# Schema version: 20081220201004
#
# Table name: beta_keys
#
#  id         :integer(11)   not null, primary key
#  key        :string(10)    
#  emailed    :integer(11)   default(0)
#  created_at :datetime      
#  user_id    :string(36)    
#

class BetaKey < ActiveRecord::Base
  belongs_to :user
  has_one :invitee, :class_name => "User"

  validates_uniqueness_of :key

  # Generates beta keys for all users to use as invites for their friends, to be 
  # run from cron each week. Users can only hold a maximum of 3 beta keys, though.
  def self.generate_for_all(count = 3)
    User.find(:all).each do |user|
      count.times do
        user.beta_keys.create unless user.beta_keys.size >= 3
      end
    end
  end

  def before_create
    chars = ("a".."z").to_a + ("A".."Z").to_a + ("1".."9").to_a
    self.key = ""
    10.times do
      self.key << chars[rand(chars.size-1)]
    end
  end
  
  def email
    emailed = 1
  end
end
