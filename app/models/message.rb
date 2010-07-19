# == Schema Information
# Schema version: 20081220201004
#
# Table name: messages
#
#  id                    :string(36)    default(""), not null, primary key
#  feed_id               :string(36)
#  title                 :string(255)
#  body                  :text          not null
#  created_at            :datetime
#  updated_at            :datetime
#  syndication_id        :string(255)
#  media_type            :string(255)
#  user_id               :string(36)
#  recipient_id          :string(36)
#  read_at               :datetime
#  context               :string(255)
#  url                   :string(255)
#  deferred_recipient_id :string(36)
#

# PMails
# - recipient_id is the user who receives the PMail
# - deferred_recipient is the user whom you can reply to, if the PMail comes from a third party (namely the PMOG user)
require 'message_errors'
class Message < ActiveRecord::Base
  include MessageErrors

  acts_as_cached

  belongs_to :feed
  belongs_to :user, :class_name => 'User', :foreign_key => :user_id
  belongs_to :recipient, :class_name => 'User', :foreign_key => :recipient_id #, :counter_cache => 'received_messages_count'
  belongs_to :deferred_recipient, :class_name => 'User', :foreign_key => :deferred_recipient_id

  @@private_api_fields = [ :feed_id, :syndication_id, :media_type ]
  @@included_api_associations = []

  # Setting the context makes the extension render the message differently.
  @@available_contexts = %w(message summon taunt summon_confirmation summon_receipt)
  cattr_reader :available_contexts

  #validates_presence_of :body, :user_id, :recipient_id
  validates_existence_of :user, :recipient
  validates_length_of :body, :maximum => 500


  # Has this message been read?
  def read?
    ! self.read_at.nil?
  end

  # Is this message unread?
  def unread?
    self.read_at.nil?
  end

  # Set the read_at field to the current date/time and clear the relevent caches
  def mark_as_read
    return if read?
    self.recipient.messages.clear_cache
    self.read_at = Time.now.utc
    self.save

    # Since we really want to keep a count of unread messages
    # We decrement the counter_cache here after a messages is
    # marked as read....
    #User.decrement_counter('received_messages_count', self.recipient.id)
  end

  # Mark this message as unread (unused as of this moment, but doesn't hurt to have it around)
  def mark_as_unread
    return if unread?
    self.recipient.messages.clear_cache
    self.read_at = nil
    self.save

    # Since we really want to keep a count of unread messages
    # We increment the counter_cache here after a messages is
    # marked as unread....
    #User.increment_counter('received_messages_count', self.recipient.id)
  end

  def before_create
    self.id = create_uuid
  end

  def for_overlay(extra_args = {})
    @output = Hash[
      :id => id,
      :context => context,
      :content => body,
      :from => user.login,
      :to => recipient.login,
      :timestamp => created_at]

    @output.merge!(:avatar => user.has_avatar? ? user.assets[0].public_filename("small") : '/images/shared/elements/user_default_small.jpg')

    unless (url.nil?)
      @output.merge!(:url => url)
    end

    # if(deferred_recipient.nil?)
    #   @output.merge!(:deferred_recipient => nil)
    # else
    unless (deferred_recipient.nil?)
      # Add the relationship here to the message JSON using the recipient and the deferred_recipient.
      @output.merge!(:deferred_recipient => deferred_recipient.login,
                     :relationship => recipient.buddies.relationship(deferred_recipient))
                     # :deferred_avatar => deferred_recipient.has_avatar? ? deferred_recipient.assets[0].public_filename("small") : '/images/shared/elements/user_default_small.jpg')
    end

    @output.merge(extra_args)
  end

  # Parse the +body+ for a +login+ prepended with an @ and return the associated +users+
  def self.determine_recipients(body)
    users = []
    return users if body.nil?
    logger.debug("Message.determine_recipients(body): " + body)

    get_logins(body).each do |login|
      #login = login.downcase.sub(/@/,'')
      login = login.downcase
      logger.debug("LOGIN TO CHECK: " + login)

      begin
        user = User.find_by_login(login)
      rescue ActiveRecord::RecordNotFound
        raise ActiveRecord::RecordNotFound.new("Couldn't find a user with the login #{login}")
      end

      logger.debug("LOGIN FOUND? " + user.to_s)

      users << user unless user.nil? or users.include? user

    end
    users
  end

  class << self

    def invite_new_player(current_user, params)
      # Is the recipient already playing?
      raise Message::RecipientAlreadyPlaying if User.find_by_email(params[:recipient])

      return false if params.blank?
      return false if current_user.blank?

      # Woot, new player not in the system, let's rock.
      Mailer.deliver_email_invite(
        :subject => "#{current_user.email} has invited you to join PMOG",
        :recipients => params[:recipient],
        :body => {
          :email => params[:recipient],
          :inviter => current_user,
          :message => params[:message]
        }
      )
    end

    def create_and_deposit(current_user, params)
      raise MessageErrors::EmptyBodyError unless params[:pmail_message]

      body = params[:pmail_message]
      raise MessageErrors::EmptyBodyError if body.strip.empty? or body.nil?

      URI.extract(body).each do |uri|
        # rescue because URI.extract treats anything with a : as a url, wtf!
        tiny_uri = tiny_url(uri) rescue next
        body.gsub!(uri, tiny_uri)
      end

      if params[:pmail_to]
        recipients = determine_recipients(params[:pmail_to])
      else
        recipients = determine_recipients(body)
      end

      raise MessageErrors::EmptyRecipientError unless recipients.size > 0
      raise MessageErrors::InsufficientDpError.new("Sorry, you don't have enough datapoints to send messages to #{recipients.size.to_s} players") unless current_user.datapoints > recipients.size
      raise MessageErrors::TooManyRecipientsError.new("Today, you can send a message to five players. You've addressed it to #{recipients.size.to_s}") unless recipients.size <= 5
      unless params[:pmail_to]
        raise MessageErrors::EmptyBodyError.new("Please provide a message to send") unless Message.body_without_users(body)
      end

      title = 'New message from ' + current_user.login

      @messages = []
      recipients.each do |recipient|
        @messages << Message.create( :title => title, :body => body, :user => current_user, :recipient => recipient)
        recipient.messages.clear_cache
      end
      current_user.reward_pings(Ping.value("Reply") * recipients.size)
      current_user.deduct_datapoints(recipients.size)
      [@messages, recipients]
    end

    def summon_player_for(current_user, params)
      recipients = determine_recipients(params[:summoned])
      raise MessageErrors::EmptyRecipientError unless recipients.size > 0
      raise MessageErrors::InsufficientDpError.new("Sorry, you don't have enough datapoints to send messages to #{recipients.size.to_s} players") unless current_user.datapoints > recipients.size
      raise MessageErrors::TooManyRecipientsError.new("Today, you can send a message to five players. You've addressed it to #{recipients.size.to_s}") unless recipients.size <= 5

      @location = Location.find(params[:location_id])
      @messages = []
      recipients.each do |recipient|
        @messages << Message.create({ :title => "#{current_user.login} has summoned you to #{@location.url}",
          :body => params[:message] || '',
          :user => current_user,
          :recipient => recipient,
          :url => @location.url,
          :context => self.available_contexts[1] })
          recipient.messages.clear_cache
      end
      current_user.reward_pings Ping.value("Reply")
      current_user.deduct_datapoints(@messages.size)
      [@messages, recipients, @location]
    end

    def send_summons_acceptance_from(current_user, summons)
      @message = Message.create({ :title => "Summons Accepted",
        :body => "#{current_user.login} has accepted your summons and traveled to #{summons.url}!",
        :user => current_user,
        :recipient => summons.user,
        :context => self.available_contexts[3] })

      summons.user.messages.clear_cache

      event_message = "accepted <a href=\"#{current_user.pmog_host}/users/#{summons.user.login}\">#{summons.user.login}'s</a> summons and traveled to #{summons.url}!"

      Event.record( :user_id => current_user.id,
                    :recipient_id => summons.user.id,
                    :context => 'summons',
                    :message => event_message )
      @message
    end

    def send_summon_receipt(current_user, summons)
      message = "You have followed a summons to #{summons.url} by #{summons.user.login}"
      message << " - they said \"#{summons.body}\" about this site" unless summons.body.empty?
      @message = Message.create({ :title => "",
        :body => message,
        :user => summons.user,
        :recipient => current_user,
        :context => self.available_contexts[4]
         })
        summons.user.messages.clear_cache
      @message
    end

    # This ensures that the message has content and not just user logins
    def body_without_users(body)
      # This regex below will match only @names that occur at the beginning
      # of the body. Those being the players the message is addressed to.
      # if an @word appears in the message itself, it will not be removed.
      return body.gsub!(/[\A]?\@[\w-]+\,?\s+/, '')
    end

    def send_pmog_message(opts = {})
      options = { :title => nil,
        :body => nil,
        :recipient => nil,
        :user => pmog_user = User.caches(:find_by_email, :with => 'self@pmog.com'),
        :deferred_recipient => nil,
        :context => nil}.merge(opts.except(:user))

      if options[:donotspam]
        return false unless options[:recipient].messages.latest.created_at < 30.minutes.ago
        return false unless options[:recipient].messages.unread_count < 5
      end

      message = Message.new(options)
      message.recipient = options[:recipient]
      message.deferred_recipient = options[:deferred_recipient] if options[:deferred_recipient]
      message.syndication_id = 'system'
      message.save
      options[:recipient].messages.clear_cache
      message
    end

    def summons_sent_all_time
      get_cache( 'summons_sent_all_time' ) do
        Message.slave_setup do
          find(:all, :select => 'COUNT(user_id) AS count, DATE(created_at) AS date', :conditions => {:context => 'summon'}, :group => 'DATE(created_at)', :order => 'DATE(created_at) ASC' )
        end
      end
    end

    def summons_confirmed_all_time
      get_cache( 'summons_confirmed_all_time' ) do
        Message.slave_setup do
          find(:all, :select => 'COUNT(user_id) AS count, DATE(created_at) AS date', :conditions => {:context => 'summon_confirmation'}, :group => 'DATE(created_at)', :order => 'DATE(created_at) ASC' )
        end
      end
    end

    protected

    # Creates an array of user logins from the body of a message.
    def get_logins(body)
      # Get's all the users in the body that the message is addressed to and not
      # the user's or @words that might be used in the content of the message.
      logins = []
      body.scan(/[\A]?\@([\w-]+)\,?\s?/).each do |login|
        logins << login[0]
      end
      return logins
    end
  end

end
