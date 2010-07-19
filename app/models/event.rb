# == Schema Information
# Schema version: 20081220201004
#
# Table name: events
#
#  id           :string(36)    default(""), not null, primary key
#  user_id      :string(36)
#  recipient_id :string(36)
#  message      :string(255)   not null
#  created_at   :datetime
#  browser      :integer(1)
#  read_at      :datetime
#  updated_at   :datetime
#  context      :string(255)
#

# For in-game messaging - user signs up, user gets mined, etc
class Event < ActiveRecord::Base
  belongs_to :user
  belongs_to :recipient, :class_name => 'User'

  has_one :event_detail

  @@order = %w(crate_stashed mission_published)
  cattr_reader :order
  @@chaos = %w(mine_deployed portal_deployed )
  cattr_reader :chaos
  @@conflict = %w(mine_tripped exploding_crate_detonated st_nick_activated watchdog_activated mine_deflected exploding_crate_deflected)
  cattr_reader :conflict
  @@friendly = %w(crate_looted mission_completed)
  cattr_reader :friendly
  @@neutral = %w(portal_used badge_unlocked comment_created connection_approved connection_removed forum_post_created forum_topic_created profile_updated steward_created user_created user_leveled user_pardoned user_suspended)
  cattr_reader :neutral
  @@available_contexts = @@order + @@chaos + @@neutral + @@conflict
  cattr_reader :available_contexts

  acts_as_cached

  validates_presence_of :user_id, :message

  named_scope :chaotic, :conditions => ["context in (?)", @@chaos]
  named_scope :neutral, :conditions => ["context in (?)", @@neutral]
  named_scope :confrontational, :conditions => ["context in (?)", @@conflict]
  named_scope :friendly, :conditions => ["context in (?)", @@friendly]
  named_scope :orderly, :conditions => ["context in (?)", @@order]

  # This will ensure that calling event.user_login will always return the value, whether
  # we query it by a join and assign user_login or not.
  def user_login
    @attributes['user_login'] ||= user.login
  end

  # Create a new event. Note that we have a browser and recipient option in here, but if you want
  # to send messages from one player to another, it's better to use the Message class instead.
  def self.record(options={})
    options = { :recipient_id => nil }.merge(options)
    e = Event.create( :user_id => options[:user_id], :recipient_id => options[:recipient_id], :message => options[:message], :browser => options[:browser], :context => options[:context])
    EventDetail.create(:event_id => e.id, :body => options[:details]) unless options[:details].nil?
  end

  def self.by_timeframe(time)
    Event.find(:all, :joins => "LEFT JOIN users ON events.user_id=users.id", :select => "events.*, users.login AS user_login", :order => 'events.created_at DESC', :conditions => ['events.created_at BETWEEN ? AND ?', time.minutes.ago.to_s(:db), Time.now.getutc.to_s(:db)])
  end

  # Short, uncached list of the latest +limit+ events
  def self.list(limit = 500)
    Event.find(:all,
               :joins => "LEFT JOIN users ON events.user_id=users.id",
               :select => "events.*, users.login AS user_login",
               :order => 'events.created_at DESC',
               :limit => limit)
  end

  # Short, cached list of the latest +limit+ events
  def self.cached_list(limit = 10)
    get_cache( "list_#{limit}", :ttl => 5.minutes ) {
      Event.list(limit)
    }
  end

  def self.recent_for(ids, limit = 10)
    Event.find(:all,
            :select => "events.*, users.login AS user_login",
            :joins => "LEFT JOIN users ON events.user_id=users.id",
            :conditions => ['events.recipient_id IN (?) AND events.created_at > ?', ids, 24.hours.ago],
            :order => "events.created_at DESC",
            :limit => limit)
  end

  def before_create
    self.id = create_uuid
  end

  def for_overlay(extra_args = {})
    @output = Hash[
      :id => id,
      :context => context,
      :content => message,
      :from => user.login,
      :to => recipient.login,
      :timestamp => created_at]

      @output.merge!(:relationship => recipient.buddies.relationship(user),
                     :avatar => user.has_avatar? ? user.assets[0].public_filename("small") : '/images/shared/elements/user_default_small.jpg')

    @output.merge(extra_args)
  end

  def read?
    not read_at.nil?
  end

  def read!
    self.read_at = Time.now
    self.save
  end

end
