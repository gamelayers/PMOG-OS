# == Schema Information
# Schema version: 20081220201004
#
# Table name: mission_shares
#
#  id         :string(36)    primary key
#  sender_id  :string(36)
#  mission_id :integer(11)
#  recipient  :string(255)
#  reward     :integer(11)   default(0)
#  fulfilled  :boolean(1)
#  created_at :datetime
#  updated_at :datetime
#  optout     :boolean(1)
#  converted  :boolean(1)
#

class MissionShare < ActiveRecord::Base
  belongs_to :sender, :class_name => 'User', :foreign_key => 'sender_id'
  belongs_to :mission

  # Must match an email address pattern
  # validates_format_of :recipient, :with => /(\A(\s*)\Z)|(\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z)/i
  validates_presence_of :mission

  def before_create
    self.id = create_uuid
  end

  def after_validation_on_create
    # send that email!!
    victim = self.find_user

    if victim
      note = "<a href=\"http://thenethernet.com/users/#{self.sender.login}\">#{self.sender.login}</a> thinks you should take this mission "+
        "<a href=\"http://thenethernet.com/missions/#{self.mission.url_name}\">#{self.mission.name}</a>."
      note += " There's #{self.reward} of their DP in it for you!" if self.reward > 0
      send_pmog_message :recipient => victim, :title => "#{self.sender.login} shared a Mission with you", :body => note
    else
      check_optout = MissionShare.find(:first, :conditions => {:recipient => self.recipient})
      unless check_optout and check_optout.optout==true
        Mailer.deliver_shared_mission(
          :subject => "[The Nethernet] #{self.sender.login} sends a Mission!",
          :recipients => self.recipient,
          :body => { :sender  => self.sender,
                     :mission => self.mission,
                     :reward  => self.reward
                   }
        ) if self.recipient.match(/(\A(\s*)\Z)|(\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z)/i)
      else
        self.optout = true
      end
    end
  end

  def fulfill!
    # WARNING DANGER - the check on whether the right user did the mission does not happen here!
    # it happens when this is called from MissionShare.fulfill_any_for.
    # well, really it happens in the missions controller's complete action. gack
    recip = self.find_user
    self.fulfilled = true # mmm, poetic

    self.sender.deduct_datapoints(self.reward)
    recip.reward_datapoints(self.reward)
    self.save

    send_pmog_message :recipient => self.sender, :title => "#{recip.login} completed the Mission you shared",
      :body => "<a href=http://thenethernet.com/users/#{recip.login}>#{recip.login}</a> completed " +
               "<a href=http://thenethernet.com/missions/#{self.mission.url_name}>#{self.mission.name}</a>." +
               "#{" You sent a "+self.reward.to_s+" DP reward." if self.reward > 0}"
  end

  def self.fulfill_any_for(user, mission)
    them = MissionShare.find(:all, :conditions => ['mission_id = ? and recipient = ? and fulfilled = ?', mission.id, user.email, false])
    them.each {|ms| ms.fulfill!}
    them
  end

  def convert!
    self.converted = true;
    self.save
  end

  def find_user
    if self.recipient.match(/(\A(\s*)\Z)|(\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z)/i)
      User.find_by_email(self.recipient)
    else
      User.find_by_login(self.recipient)
    end
  end

  private
  def send_pmog_message(options={})
    if options[:donotspam]
      return false unless options[:recipient].messages.latest.created_at < 30.minutes.ago
      return false unless options[:recipient].messages.unread_count < 5
    end
    pmog_user = User.caches(:find_by_email, :with => 'self@pmog.com')
    Message.create( :title => options[:title], :body => options[:body], :recipient => options[:recipient], :user => pmog_user )
    options[:recipient].messages.clear_cache
  end
end
