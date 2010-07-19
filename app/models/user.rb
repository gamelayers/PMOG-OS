# == Schema Information
# Schema version: 20081220201004
# fake
#
# Table name: users
#
#  id                        :string(36)    default(""), not null, primary key
#  login                     :string(255)
#  email                     :string(255)
#  crypted_password          :string(40)
#  salt                      :string(40)
#  created_at                :datetime
#  updated_at                :datetime
#  last_login_at             :datetime
#  remember_token            :string(255)
#  remember_token_expires_at :datetime
#  visits_count              :integer(11)   default(0)
#  time_zone                 :string(255)   default("Etc/UTC")
#  identity_url              :string(255)
#  forename                  :string(255)
#  surname                   :string(255)
#  url                       :string(255)
#  date_of_birth             :date
#  gender                    :string(1)
#  country                   :string(255)
#  datapoints                :integer(11)   default(0)
#  primary_association       :string(255)
#  secondary_association     :string(255)
#  tertiary_association      :string(255)
#  total_datapoints          :integer(11)   default(0), not null
#  beta_key_id               :integer(11)
#  motto                     :string(255)
#  privacy_level             :string(255)   default("public")
#  current_level             :integer(11)   default(1)
#  posts_count               :integer(11)   default(0), not null
#  average_rating            :integer(11)   default(0)
#  total_ratings             :integer(11)   default(0)
#  ratings_count             :integer(11)   default(0)
#  lifetime_pings            :integer(11)   default(0)
#  available_pings           :integer(11)   default(0)
#

require 'digest/sha1'

class User < ActiveRecord::Base
  include ActionView::Helpers::DateHelper
  include AuthenticatedBase
  include Pronouner

  LOGIN_MIN_LENGTH = 3 unless defined?(LOGIN_MIN_LENGTH)
  LOGIN_MAX_LENGTH = 40 unless defined?(LOGIN_MAX_LENGTH)
  LOGIN_NAME_RANGE = LOGIN_MIN_LENGTH..LOGIN_MAX_LENGTH unless defined?(LOGIN_NAME_RANGE)
  EMAIL_MIN_LENGTH = 6 unless defined?(EMAIL_MIN_LENGTH)
  EMAIL_MAX_LENGTH = 100 unless defined?(EMAIL_MAX_LENGTH)
  EMAIL_RANGE = EMAIL_MIN_LENGTH..EMAIL_MAX_LENGTH unless defined?(EMAIL_RANGE)
  SEX = [['Male', 'm'], ['Female', 'f']] unless defined?(SEX)

  acts_as_authorizable
  acts_as_authorized_user
  #acts_as_tagger
  acts_as_taggable
  acts_as_favorite_user
  acts_as_favorite

  acts_as_cached
  after_save :expire_cache

  # BASIC PLAYER DATA (user data split to other tables)
  has_one :user_level
  has_one :inventory, :as => :owner, :extend => InventoryExtension
  has_one :ability_status, :dependent => :destroy
  has_one :user_secret, :dependent => :destroy
  has_one :user_activity

  # Note that most associations are dependent => destroy save for a few which are explicitly
  # not, such as forums, missions and so on, where we want the data to remain in the game, but
  # which we can transfer ownership to the PMOG user.
  has_many :assets, :as => :attachable, :dependent => :destroy
  has_many :ratings, :as => :rateable, :dependent => :destroy # i can has ratings?
  has_many :npcs
  has_many :bird_bots
  has_many :watchdogs, :dependent => :destroy
  has_many :st_nicks, :dependent => :destroy
  has_many :mines, :dependent => :destroy
  has_many :portals, :dependent => :destroy
  has_many :crates, :dependent => :destroy
  has_many :giftcards, :dependent => :destroy
  has_many :grenades, :dependent => :destroy, :foreign_key => :victim_id
  has_many :ballistic_nicks, :dependent => :destroy, :foreign_key => :victim_id
  has_many :lightposts, :order => 'lightposts.updated_at DESC', :dependent => :destroy
  has_many :events, :order => 'events.created_at DESC', :dependent => :destroy, :extend => EventsExtension
  has_many :system_events, :class_name => "Event", :order => 'events.created_at DESC', :foreign_key => :recipient_id, :extend => SystemEventsExtension
  has_many :daily_domains, :dependent => :destroy, :extend => DailyDomainsExtension
  has_many :daily_log_ins, :dependent => :destroy, :extend => DailyLogInsExtension
  has_many :preferences, :order => 'preferences.created_at DESC', :dependent => :destroy, :extend => UserPreferencesExtension
  has_many :subscriptions
  has_many :missions, :dependent => :destroy, :extend => UserMissionsExtension
  has_many :quests, :dependent => :destroy

  has_many :status_effects, :conditions => ["charges >= ?", 0], :dependent => :destroy

  # Action History
  has_many :tool_uses, :dependent => :destroy, :extend => ToolUsesExtension
  has_many :upgrade_uses, :dependent => :destroy, :extend => UpgradeUsesExtension
  has_many :ability_uses, :dependent => :destroy, :extend => AbilityUsesExtension
  has_many :misc_action_uses, :dependent => :destroy, :extend => MiscActionUsesExtension

  has_many :daily_classpoints, :class_name => "DailyClasspoints", :dependent => :destroy

  # Replacing old habtm associations with has_many :through
  has_many :badgings
  has_many :badges, :through => :badgings


  # Note the foreign keys in here, so that we can figure out which messages are for you, and which are created by you
  has_many :messages, :foreign_key => :recipient_id, :dependent => :destroy, :conditions => ["syndication_id IS NULL"], :extend => UserMessagesExtension
  has_many :sent_messages, :class_name => 'Message', :foreign_key => :user_id, :dependent => :destroy, :extend => UserSentMessagesExtension

  # Beta Keys
  has_many :beta_keys # people you invite
  belongs_to :beta_key # who you were invited by

  # Adminnings
  has_many :soul_marks, :foreign_key => 'player_id'

  # Forums
  has_many :topics
  has_many :posts
  has_many :queued_missions, :order => 'created_at DESC'
  has_many :missions_queued, :through => :queued_missions, :source => :mission
  has_many :suspensions, :order => 'expires_at DESC'
  delegate :suspended?, :suspended_until, :suspended_on, :suspended_reason, :to => "suspensions.nil? ? false : suspensions"

  has_many :awsmattacks

  has_and_belongs_to_many :buddies, :extend => BuddiesExtension, :order => 'last_login_at DESC'

  composed_of :tz, :class_name => 'TZInfo::Timezone', :mapping => %w( time_zone time_zone )

  #validates_each :date_of_birth do |record, attr, value|
  #  record.errors.add attr, "Sorry, You must be over 13 years old to play PMOG." if value && value > Date.new((Date.today.year - 13),(Date.today.month),(Date.today.day))
  #  record.errors.add attr, "is required." unless value
  #end

  # Must match an email address pattern
  validates_format_of :email, :with => /(\A(\s*)\Z)|(\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z)/i, :allow_nil => true, :allow_blank => true

  # Must match a URL pattern
  validates_format_of :url, :with => /^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$/ix,
                            :allow_nil => true,
                            :allow_blank => true,
                            :message => 'must start with http:// or https:// and end with a .tld (Top level domain)'

  # No funky characters in the login
  validates_format_of :login   , :with => /^[0-9a-z_-]+$/i, :message => 'can contain only numbers and letters.'
  validates_uniqueness_of :email, :case_sensitive => false, :allow_nil => true, :allow_blank => true
  validates_uniqueness_of :login, :case_sensitive => false
  validates_uniqueness_of :identity_url, :case_sensitive => false, :if => Proc.new { |user| ! user.identity_url.blank? }
  validates_length_of :identity_url, :minimum => 3, :allow_nil => true, :allow_blank => true
  validates_length_of :login, :within => LOGIN_NAME_RANGE
  validates_length_of :email, :within => EMAIL_RANGE, :allow_nil => true, :allow_blank => true
  validates_cleanliness_of :login

  # Protect internal methods from mass-update.
  attr_accessible :login, :email, :password, :password_confirmation, :created_at, :time_zone, :identity_url, :forename, :surname, :gender, :date_of_birth, :country, :url, :last_log_in, :motto, :privacy_level, :average_rating, :total_ratings, :signup_source, :signup_version
  @@private_api_fields = ["id", :total_ratings, :posts_count, :average_rating, :beta_key_id, :remember_token, :remember_token_expires_at, :visits_count, :updated_at, "crypted_password", :salt, :email, :password, :password_confirmation, :privacy_level, :identity_url, :ratings_count, :country, :last_login_at, :gender, :date_of_birth, :time_zone]
  cattr_reader :private_api_fields
  @@included_api_associations = [ :assets, :missions, :npcs, :bird_bots, :tags ]

  class UserError < PMOG::PMOGError
  end

  class PlayerNotFound < UserError
    def default
      "Player not found, are you sure you spelled the name right?"
    end
  end

  class InventoryError < UserError
    def default
      "Error in user inventory."
    end
  end

  class InsufficientToolsError < InventoryError
    def default
      "You don't have enough tools to perform this action!"
    end
  end

##NOTE dont delete this please, this is some scratch work that i'd like to integrate more widely if possible - alex
#  class InsufficientToolsError < InventoryError
#    attr_reader :tool_name
#    def initialize(tool_name)
#      @message = "You don't have enough #{@tool_name.to_s.pluralize.titleize} to perform this action!"
#    end
#  end

  class InsufficientExperienceError < UserError
    def default
      "Your level is too low to use this feature!"
    end
  end

  class InsufficientDPError < UserError
    def default
      "You do not have enough DP for this purchase!"
    end
  end

  class InsufficientPingsError < UserError
    def default
      "You do not have enough pings for this purchase!"
    end
  end

  def before_create
    self.id = create_uuid
    self.login = create_permalink(self.login)
  end

  def self.find_by_login(login)
    find( :first, :conditions => { :login => login } ) or raise ActiveRecord::RecordNotFound
  end

  def to_param
    login
  end

  # Note that this is different from the user data added to the
  # browser overlays by +current_user_data+ from +ApplicationController+
  # In this context +to_hash+ can be used in conjuction with the
  # users/show partial, to display their profile.
  def to_hash(opts = {})
    id = self.id
    return { :id => id,
             :type => self.class.to_s,
             :subject => '',
             :body => yield }.merge(opts)
  end

  def has_enough_datapoints?(value)
    return true if (self.datapoints - value) >= 0
    return false if (self.datapoints - value) < 0
  end
  # So that we can call User.to_hash
  def self.to_hash(opts = {}, &block)
    User.new.to_hash({ :type => 'User' }.merge(opts), &block)
  end

  # Boolean to reference the users nsfw preference.
  def allow_nsfw?
    self.preferences.get(Preference.preferences[:allow_nsfw][:text]).value.to_bool rescue false
  end

  def age
    get_cache( 'age_' + id.to_s ) { calculate_age }
  end

  def admirers
    Buddy.find(self.id).users
  end

  def reward_paycheck
    if self.paycheck_at.nil? || (Time.now.utc >= self.paycheck_at)
      dp_per_hour = GameSetting.value("DP Per Hour").to_i
      reward_datapoints(current_level * (admin_or_steward? ? (dp_per_hour * 10) : dp_per_hour))
      self.paycheck_at = Time.now.utc + 1.hour
      save
    end
  end



  def current_level
    if self.user_level.nil?
      self.user_level = UserLevel.create
      self.user_level.auto_assign_primary
    end
    self.user_level.primary
  end

  def primary_association
    self.user_level.primary_class
  end

  # double the stub; start using this and i'll delete the association one later when i have time to clean up
  def primary_class
    self.user_level.primary_class
  end

  def level_dp_percentage
    Level.dp_percentage(self, 'primary')
  end

  def level_cp_percentage
    Level.cp_percentage(self, 'primary')
  end

  # A text string describing how far the user has to go before reaching the next level
  def levelup_requirements(options = {})
    Level.requirements(self, options)
  end

  # Returns a hash containing the users' level for each tool
  # exactly the same as Level.all_levels_for(self), but this is where it really belongs
  # we don't cache this hash because each component is cached separately and has its own expiry rules
  def levels
    Hash[
      :bedouin => self.user_level.bedouin,
      :benefactor => self.user_level.benefactor,
      :destroyer => self.user_level.destroyer,
      :pathmaker => self.user_level.pathmaker,
      :seer => self.user_level.seer,
      :vigilante => self.user_level.vigilante
    ]
  end

  # Increase the users' datapoints and add that to their total datapoints also.
  # Always use this for awarding the user points.
  def reward_datapoints(amount, lifetime=true)
    return if amount <= 0
    self.datapoints = self.datapoints + amount

    if(lifetime.to_bool)
      old_level = current_level

      level_up = true if current_level < 20 && Level.req(current_level + 1, :dp) <= self.total_datapoints + amount

      self.total_datapoints = self.total_datapoints + amount
      self.save(false)

      if level_up
        self.user_level.expire_all
        self.user_level.reload
        self.user_level.levelup_event_for("primary") if old_level < self.current_level
      end
    else
      self.save(false)
    end

    self.expire_cache(self.id)
  end

  # Increase the users' pings and add that to their total datapoints also.
  # Always use this for awarding the user pings.
  def reward_pings(amount, lifetime=true)
    return if amount <= 0

    self.available_pings = self.available_pings + amount
    self.lifetime_pings = self.lifetime_pings + amount if lifetime.to_bool
    self.expire_cache(self.id)
    self.save(false)
  end

  def add_bacon(amount, &block)
    self.transaction do
      self.bacon += amount
      self.bacon = 0 if self.bacon < 0
      self.max_bacon_per_buy = amount if amount > self.max_bacon_per_buy # record how much this person spent in one shot
      yield if block_given?
      self.expire_cache(self.id)
      self.save!
    end
  end

  # Decrease a users datapoints by +amount+ and clear the user cache,
  # but not their total_datapoints. Sets a datapoint floor at 0
  def deduct_datapoints(amount)
    return if amount <= 0

    self.datapoints -= amount
    self.datapoints = 0 if self.datapoints < 0

    self.save(false)
    #self.expire_cache(self.id)
  end

  # Decrease a users pings by +amount+ and clear the user cache,
  # but not their lifetime_pings. Sets a pings floor at 0
  def deduct_pings(amount)
    return if amount <= 0

    self.available_pings -= amount
    self.available_pings = 0 if self.available_pings < 0

    self.save(false)
    #self.expire_cache(self.id)
  end

  # Buy the relevant number of tools, if the user can afford it
  def purchase(tool_name, instances)
    Shoppe.buy(self, { :order => {:tools => Hash[tool_name, instances]}})
  rescue Shoppe::EmptyOrderError, Shoppe::InsufficientFundsError, Shoppe::TooManyItemsError
    false
  end

# DEPRECATED 09-01-19
#  def associations
#    [ self.primary_association.downcase, self.secondary_association.downcase, self.tertiary_association.downcase ]
#  end

  # Picking a +last_active+ date as the last time the user model changed
  def last_active
    self.updated_at
  end

  # What was the last version of the extension this user used?
  # - note the USE INDEX in the query, which forces MySQL to use the right index
  def last_version
    get_cache('last_version', :ttl => 1.day) do
      version = DailyActivity.find_by_sql( ["SELECT extension_version FROM daily_activities USE INDEX (index_daily_activities_on_user_id_and_created_on) WHERE (daily_activities.user_id = ?) ORDER BY created_on DESC LIMIT 1", self.id] )
      version.empty? ? 'N/A' : version[0].extension_version.gsub(/auth_token.*/, '') # To refrain from returning the auth token that accidentally made it into the db for some users.
    end
  end

  # Do I haz avatar?
  def has_avatar?
    get_cache('has_avatar?', :ttl => 1.day) do
      assets.size > 0 && ! assets[0].nil?
    end
  end

# DEPRECATED 09-02-05 by alex, the new inventory does not really work with the old equippable schema
# since we're only tracking armor now anyway, i moved that to ability_statuses
#
#  # Take one of +tool_name+ from your inventory and place it in your equipped_items
#  def equip(tool_name)
#    instance = inventory.remove(tool_name)
#    equipped_items.equip(instance) unless instance.nil?
#  end
#
#  # Remove one of +tool_name+ and return it to your inventory
#  def unequip(tool_name)
#    tool = Tool.cached_single(tool_name.to_s)
#    charges = equipped_items.unequip(tool)
#    inventory.replace(tool, charges) unless charges == 0
#  end
#
#  # Returns the status of an equipped_item
#  def equipped?(tool_name)
#    equipped_items.cached_status(tool_name)
#  end
#
#  # Returns the first instance of this equipped item
#  def equipped_item(tool_name)
#    tool = Tool.cached_single(tool_name.to_s)
#    equipped_items.select{ |item| item.tool_id == tool.id }[0]
#  end

  def deplete_armor
    ability_status.deplete_armor
  end

  def destroy_armor
    ability_status.destroy_armor
  end

  def toggle_armor
    ability_status.toggle_armor
  end

  def is_armored?
    ability_status.armor_equipped.to_bool
  end

  def dodge_roll?
    dodge_settings = Ability.cached_single(:dodge)

    # if the player meets all the requirements, roll the dice and return true or false
    user_level.bedouin >= dodge_settings.level &&
    ability_status.dodge.to_bool &&
    available_pings >= dodge_settings.ping_cost &&
    (rand(100) <  dodge_settings.percentage)
  end

  def disarm_roll?
    disarm_settings = Ability.cached_single(:disarm)

    # if the player meets all the requirements, roll the dice and return true or false
    available_pings >= disarm_settings.ping_cost &&
    user_level.bedouin >= disarm_settings.level &&
    ability_status.disarm.to_bool &&
    (rand(100) < disarm_settings.percentage)
  end

  # Create a key that indicates the status of a +User+ by reflecting on all
  # associations and creating a string out of the relevant association sizes
  def version
    association_sizes = []
    #self.class.reflect_on_all_associations.each do |assoc|
     for assoc in self.class.refect_on_all_associations
      association_data = self.send(assoc.name.to_s)
      association_sizes << (association_data.nil? ? 0 : association_data.size)
    end
    [ updated_at, association_sizes  ].flatten.join(':')
  end

  # Find the next sequential user
  def next
    get_cache( "next_#{id}", :ttl => 1.week ) { self.class.find(:first, :conditions => ['created_at > ?', created_at], :order => 'created_at ASC') }
  end

  # Find the previous sequential user
  def prev
    get_cache( "prev_#{id}", :ttl => 1.week ) { self.class.find(:first, :conditions => ['created_at < ?', created_at], :order => 'created_at DESC') }
  end

  # Convenience method to check if a user already has a badge.
  def has_badge?(badge)
    self.badges.exists?(:name => badge)
  end

  def next_invite_badge
    badge_path = "/images/shared/badges/medium/"
    if ! has_badge?("Inviting")
      b = Badge.find_by_name("Inviting")
      return badge_path + b.image
    elsif ! has_badge?("Alluring")
      b = Badge.find_by_name("Alluring")
      return badge_path + b.image
    else
      b = Badge.find_by_name("Magnetic")
      return badge_path + b.image
    end
  end

  # Cached list of all users
  def self.cached_list(options = {})
    options = { 'page' => 1, :per_page => 20 }.merge(options)

    get_cache( "list_#{options.to_s}" ) {
      @users = User.paginate( :all,
                              :order => 'login ASC',
                              :page => options['page'],
                              :per_page => options[:per_page] )
    }
  end

  # Caching role based authentication
  def cached_has_role?(role)
    get_cache( "has_role_#{role}_#{id}" ) { has_role?(role) }
  end

  def self.find_by_param(*args)
    find_by_login *args
  end

  # A cheap way of doing 'users online' that stops us from updating the database on every user request
  # since we only update last_login_at on login and remember me
  def self.online_now(limit = 5)
    @online_now ||= User.find( :all, :order => 'last_login_at DESC', :include => [ :assets ], :limit => limit, :group => 'users.id' )
  end

  # Reward the inviter and make them approved allies
  def self.set_betakey_for(user, cookie)
    beta_key = BetaKey.find( :first, :conditions => { :key => cookie } )
    if beta_key
      user.beta_key = beta_key
      user.save(false)

      user.beta_key.user.reward_datapoints(GameSetting.value('Invite DP').to_i)
      user.beta_key.user.reward_pings(GameSetting.value('Invite Pings').to_i)

      # Make the inviter and the invitee friends, unless you were invited by
      # the default PMOG user
      unless user.beta_key.user.login.downcase == 'pmog' || user.beta_key.user.login.downcase == 'thenethernet'
        buddy = Buddy.find(user.beta_key.user.id)
        Buddy.connection.insert( "insert into buddies_users (buddy_id, user_id, accepted, type, requires_approval, created_at, updated_at) values ('#{buddy.id}', '#{user.id}', 1, 'ally', 0, '#{Time.now.to_s(:db)}', '#{Time.now.to_s(:db)}')" )
        Buddy.connection.insert( "insert into buddies_users (buddy_id, user_id, accepted, type, requires_approval, created_at, updated_at) values ('#{user.id}', '#{buddy.id}', 1, 'ally', 0, '#{Time.now.to_s(:db)}', '#{Time.now.to_s(:db)}')" )

        Event.record( :user_id => buddy.id,
                      :recipient_id => buddy.id,
                      :context => 'invitation',
                      :message => "invited <a href=\"#{user.pmog_host}/users/#{user.login}\">#{user.login}'s</a> to play TheNethernet" )
      end
    end
  end

  # Convenience method to get the requested user missions detail. Defaults to "taken"
  def get_mission_data(params, sort='missions.created_at DESC')
    get_cache(params[:mission_type] + '_' + sort, :tll => 1.day) do
      case params[:mission_type]
        when 'generated'      then self.missions.find(:all, :order => sort)
        when 'favorites'      then Mission.favourites(self)
        when 'drafts'         then Mission.find_all_drafts_for_user(self, sort)
        when 'queued'         then self.missions_queued.find(:all, :order => sort)
        when 'acquaintances'  then self.missions.acquaintances_latest_missions(10, sort)
        when 'recommended'    then Mission.find_top(params, self, nil, false)
        else                       Mission.taken(self)
      end
    end
  end

  def subscribed_ids
    subs_ids = []
    self.subscriptions.each do |sub|
      subs_ids << sub.subscribeable_id
    end
    subs_ids
  end

  def public_subscribed_ids
    subs_ids = []
    self.subscriptions.each do |sub|
      if sub.subscribeable.is_a? Topic and !sub.subscribeable.forum.private?
        subs_ids << sub.subscribeable_id
      end
    end
    subs_ids
  end

  def init_preferences
    # Adds the preferences to every user if they don't already have them defined (should be everyone first migration)
    # Create default User Preferences for the user.
    Preference.preferences.each {|option|
      self.preferences.toggle option[1][:text], option[1][:default]
    }
  end

  def calculate_average_rating
    self.average_rating = ratings.average('score', :conditions => ['rateable_id = ?', self.id]).to_i
    self.save(false)
  end

  def calculate_total_ratings
    self.total_ratings = ratings.count
    self.save(false)
  end

  # Check to see if the user has the specific role
  def has_role?(rolename)
    self.roles.find_by_name(rolename) ? true : false
  end

  def admin?
    self.has_role?('site_admin')
  end

  def npc?
    self.has_role?('npc')
  end

  def steward?
    self.has_role?('steward')
  end

  def admin_or_steward?
    self.has_role?('steward') or self.has_role?('site_admin')
  end

  def self.find_all_by_role(rolename)
    User.find(:all,
      :joins => 'inner join roles_users on users.id = roles_users.user_id inner join roles on roles.id = roles_users.role_id',
      :conditions => ['roles.name = ?', rolename]
    )
  end

  def mission_makers
    self.missions.completed.map(&:user)
  end

  def mission_takers
    alladem = []
    made_missions = Mission.find :all, :conditions => {:user_id => self.id}
    made_missions.each do |mish|
      alladem += mish.takers
    end unless made_missions.nil?
    alladem.delete_if {|user| user==self}.uniq!
  end

  def mine_trippers
    User.find_by_sql(["select distinct u.* from users u
      inner join events e on e.user_id = u.id
      where e.message LIKE ?",
      "%>#{self.login}</span>'s mine."]
    )
  end

  def crate_makers
    User.find_by_sql(["select distinct u.* from users u
      inner join messages m on m.recipient_id = u.id
      where m.user_id = ? and m.body LIKE ?",
      User.find_by_login('pmog').id, '%>' + self.login + '</span> just looted one of your crates!']
    ).delete_if {|user| user.login=='pmog'}.uniq!
  end

  def portal_makers
    Portal.find_by_sql(["select distinct p.* from portals p
      inner join portals_users pu on pu.portal_id = p.id
      where pu.user_id = ?", self.id]
    ).map(&:user).delete_if {|user| user==self}.uniq!
  end

  # The location_id of this users profile page
  def profile_location_id
    get_cache('profile_location_id') do
      Location.find_or_create_by_url(self.pmog_host + '/users/' + self.login).id
    end
  end

  # A JSON representaion of a user
  def to_json_overlay(options = {})
    overlay = {
      :unread_messages => self.messages.unread_count,
      :login => login,
      :forename => forename,
      :surname => surname,
      :gender => gender,
      :current_level => current_level,
      :primary_association => user_level.primary_class, #FIXME refactor this to class, needs to match extension
      :motto => motto,
      :datapoints => datapoints,
      :total_datapoints => total_datapoints,
      :levels => levels,
      :last_active => (last_active.nil? ? '-' : time_ago_in_words(last_active) + " ago"),
      :registered => time_ago_in_words(created_at) + " ago",
      :available_pings => available_pings,
      :lifetime_pings => lifetime_pings,
      :profile_location_id => profile_location_id,
      :rating => average_rating,
      :total_ratings => total_ratings,
      :age => age,
      :country => country,
      :recent_events => recent_events,
      :recent_badges => recent_badges,
      :inventory => ( options[:include_inventory] ? self.inventory.get_tools_as_hash : {} ) # FIXME change to not sending :inventory at all on false (but only if the extension doesn't care).  check w/ marc -alex
    }

    if self.assets[0]
      overlay[:avatar] = self.assets[0].public_filename
      overlay[:avatar_mini] = self.assets[0].public_filename("mini")
      overlay[:avatar_tiny] = self.assets[0].public_filename("tiny")
      overlay[:avatar_small] = self.assets[0].public_filename("small")
      overlay[:avatar_toolbar] = self.assets[0].public_filename("toolbar")
    else
      overlay[:avatar] = '/images/shared/elements/user_default.jpg'
      overlay[:avatar_mini] = '/images/shared/elements/user_default_mini.jpg'
      overlay[:avatar_tiny] = '/images/shared/elements/user_default_tiny.jpg'
      overlay[:avatar_small] = '/images/shared/elements/user_default_small.jpg'
      overlay[:avatar_toolbar] = '/images/shared/elements/user_default_toolbar.jpg'
    end
    overlay
  end

  def recent_badges
        badges.reverse[0..3].map { |x|
          { :name => x.name, :image => self.pmog_host + "/images/shared/badges/small/" + x.image, :url => self.pmog_host + '/guide/badges/' + x.url_name }
        }
  end

  def recent_events
    self.events.cached_latest(10).map { |x|
      # This gsub strips HTML saving us drama in the extension
      { :message => x.message.gsub(/<\/?[^>]*>/, "") }
    }
  end

  # A hack to get the slave_setup working from a user model as calling
  # self.slave_setup correctly leaves us connected to the slave afterwards
  def order_points
    User.order_points(self)
  end

  # A hack to get the slave_setup working from a user model as calling
  # self.slave_setup correctly leaves us connected to the slave afterwards
  def chaos_points
    User.chaos_points(self)
  end

  # Note that we don't use a 'tool_id IN (?)' query here as that results
  # in a filesort, so we run a series of individual counts and increment the counts
  def self.order_points(user)
    memcache_name = "#{user.login}_order_points"

    get_cache(memcache_name, :ttl => 3.hours) do
      User.slave_setup do
        crate_id = Tool.cached_single('crates').id
        lightpost_id = Tool.cached_single('lightposts').id
        armor_id = Tool.cached_single('armor').id

        counts = OpenStruct.new
        counts.daily = counts.weekly = counts.monthly = counts.overall = 0
        [crate_id, lightpost_id,armor_id].each do |tool_id|
          # Using USE INDEX to make sure the right index is used
          counts.daily += ToolUse.find_by_sql( [ "SELECT count(id) AS count FROM tool_uses USE INDEX (index_tool_uses_on_user_id_and_tool_id_and_created_at) WHERE user_id = ? AND tool_id = ? AND created_at >= ?", user.id, tool_id, 1.day.ago ] )[0].count.to_i rescue 0
          counts.weekly += ToolUse.find_by_sql( [ "SELECT count(id) AS count FROM tool_uses USE INDEX (index_tool_uses_on_user_id_and_tool_id_and_created_at) WHERE user_id = ? AND tool_id = ? AND created_at >= ?", user.id, tool_id, 1.week.ago ] )[0].count.to_i rescue 0
          counts.monthly += ToolUse.find_by_sql( [ "SELECT count(id) AS count FROM tool_uses USE INDEX (index_tool_uses_on_user_id_and_tool_id_and_created_at) WHERE user_id = ? AND tool_id = ? AND created_at >= ?", user.id, tool_id, 1.month.ago ] )[0].count.to_i rescue 0
          counts.overall += ToolUse.find_by_sql( [ "SELECT count(id) AS count FROM tool_uses USE INDEX (index_tool_uses_on_user_id_and_tool_id_and_created_at) WHERE user_id = ? AND tool_id = ?", user.id, tool_id ] )[0].count.to_i rescue 0
        end
        counts
      end
    end

    rescue Exception => e
      return OpenStruct.new(:daily => 0, :weekly => 0, :montly => 0, :overall => 0)
  end

  def self.chaos_points(user)
    memcache_name = "#{user.login}_chaos_points"

    get_cache(memcache_name, :ttl => 3.hours) do
      User.slave_setup do
        mine_id = Tool.cached_single('mines').id
        portal_id = Tool.cached_single('portals').id
        st_nick_id = Tool.cached_single('st_nicks').id
        watchdog_id = Tool.cached_single('watchdogs').id

        counts = OpenStruct.new
        counts.daily = counts.weekly = counts.monthly = counts.overall = 0
        [mine_id, portal_id, st_nick_id, watchdog_id].each do |tool_id|
          counts.daily += ToolUse.count(:conditions => [ 'user_id = ? AND tool_id = ? and created_at >= ?', user.id, tool_id, 1.day.ago ])
          counts.weekly += ToolUse.count(:conditions => [ 'user_id = ? AND tool_id = ? and created_at >= ?', user.id, tool_id, 1.week.ago ])
          counts.monthly += ToolUse.count(:conditions => [ 'user_id = ? AND tool_id = ? and created_at >= ?', user.id, tool_id, 1.month.ago ])
          counts.overall += ToolUse.count(:conditions => [ 'user_id = ? AND tool_id = ?', user.id, tool_id ])
        end
        counts
      end
    end

    rescue Exception => e
      return OpenStruct.new(:daily => 0, :weekly => 0, :montly => 0, :overall => 0)
  end

  # Track the number of attempted logins from this +remote_ip+ address
  # - increments the number of total failed attempts if the login failed
  # - updates the time of the +last_login_attempt+ for use with User#login_delay
  # - stores a failed-login-per-ip counter in memcached for 5 minute (300 seconds)
  # - if there are more than +lock_limit+ attempts from this ip, the account is locked
  # - if there are more than +absolute_lock_limit+ attempts in total (from any ip), the account is locked
  # - memcached-backed rate limiting, adapted from http://simonwillison.net/2009/Jan/7/ratelimitcache/
  def record_login_attempt(remote_ip, successful = false, lock_limit = 25, absolute_lock_limit = 1000)
    if successful
      # Reset the main counter, let the memcached data expire automatically
      self.failed_login_attempts = 0
    else
      # Increment the various counters and lock the account if required
      key = 'ratelimit_' + remote_ip
      login_attempts_for_ip = (User.fetch_cache(key) || 0) + 1
      User.set_cache(key, login_attempts_for_ip, 300)
      self.failed_login_attempts += 1

      self.lock_account if login_attempts_for_ip > lock_limit
      self.lock_account if self.failed_login_attempts > absolute_lock_limit
    end

    # Track the IP address of the last attempt, and make sure that the date of the
    # last attempted login honours the relevant timezone (we'll need this to be in
    # sync when we calculate the login delay)
    self.remote_ip = remote_ip
    self.last_login_attempt = self.tz.now
    self.save(false)
  end

  # The number of seconds we require users to wait between failed login attempts
  # - the more failed attempts there are, the longer a user must wait
  def login_delay(seconds_to_delay = 2)
    self.failed_login_attempts > 0 ? (self.failed_login_attempts * seconds_to_delay) : seconds_to_delay
  end

  # Prevent a user from attempting to login again and again
  # - doesn't clear their cookie or session data, but does wipe their remember tokens
  def lock_account
    self.remember_token_expires_at = nil
    self.remember_token = nil
    self.locked = true
    self.save!
  end

  # Allow a user to login again, following repeated login failures
  def unlock_account
    self.locked = false
    self.save!
  end

  # Has the user signed up within the last 10 minutes?
  def recently_signed_up?
    self.created_at > 10.minutes.ago
  end

  protected
  def calculate_age
    if date_of_birth.nil?
      return nil
    else
      return ( ( Date.today.strftime( "%Y%m%d" ).to_i - date_of_birth.strftime( "%Y%m%d" ).to_i ) / 10000 ).to_i
    end
  end

end
