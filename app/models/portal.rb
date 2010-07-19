# == Schema Information
# Schema version: 20081220201004
#
# Table name: portals
#
#  id             :string(36)    primary key
#  user_id        :string(36)
#  location_id    :string(36)
#  destination_id :string(36)
#  created_at     :datetime
#  updated_at     :datetime
#  average_rating :integer(11)   default(0)
#  branch_id      :string(36)
#  title          :string(255)
#  nsfw           :boolean(1)
#  charges        :integer(11)   default(5)
#

class Portal < ActiveRecord::Base
  include AvatarHelper
  belongs_to :location
  #belongs_to :old_location
  belongs_to :user
  belongs_to :destination, :class_name => 'Location'

  acts_as_cached
  acts_as_voteable

  has_many :ratings, :as => :rateable, :dependent => :destroy
  has_many :dismissals, :as => :dismissable, :dependent => :destroy, :extend => DismissableExtension

  has_many :transportations
  has_many :users, :through => :transportations

  validates_presence_of :location_id, :destination_id, :user_id, :title

  # Protect internal methods from mass-update.
  attr_accessible :title, :nsfw, :destination_id, :location_id, :charges, :abundant

  # Restricted attributes and included association for JSON output
  cattr_accessor :private_api_fields, :included_api_associations
  @@private_api_fields = []
  @@included_api_associations = [ :user, :ratings ]

  named_scope :popular, :conditions => ["average_rating > 3"]

  named_scope :first_valid, lambda { |user, avg_rating, nsfw| { :conditions => [ "id not in (SELECT dismissals.dismissable_id from dismissals WHERE dismissals.user_id = ? AND average_rating >= ? #{nsfw} )", user.id, avg_rating ] } }


  class PortalError < PMOG::PMOGError
  end

  class BlankParams < PortalError
    def default
      "Invalid parameters supplied.  We were unable to process your request.  Please try again."
    end
  end

  class BlankHint < PortalError
    def default
      "You must provide a hint for passersby."
    end
  end

  class BlankDestination < PortalError
    def default
      "You must provide a destination for your Portal."
    end
  end

  class InvalidPortal < PortalError
    def default
      "We're sorry, but an error occured while creating your Portal.  Please try again."
    end
  end

  # Decrement the +charges+ for this tool, destroying if it neccessary
  def deplete
    self.charges -= 1
    if self.charges <= 0
      self.destroy

      Event.record :context => 'portal_expired',
        :user_id => self.user.id,
        :recipient_id => self.user.id,
        :message => "just had a Portal expire!",
        :details => "You built this portal from <a href=\"#{self.location.url}\">#{self.location.url}</a> to <a href=\"#{self.destination.url}\">#{self.destination.url}</a> on #{self.created_at.to_s}."
    else
      self.save
    end
  end

  def rate(current_user, score = 3)
    current_user = User.find(current_user) if current_user.class == String

    # give the seer 1 more dp for getting a reaction out the person
    self.user.reward_datapoints 1, false

    # Normalize the score to fall inside the acceptable range.
    score = [5,[0,score.to_i].max].min
    rating = ratings.find_or_initialize_by_user_id( :user_id => current_user.id)
    rating.score = score
    calculate_average_rating if rating.save
  end

  def transport(current_user)
    # add this user to the list of ppl who took this portal
    users << current_user unless users.include? current_user

    self.user.misc_action_uses.reward :portal_transportation

    ### ABUNDANT ###
    if abundant
      self.user.reward_datapoints 2, false

      Event.record :context => 'abundant_portal_used',
        :user_id => current_user.id,
        :recipient_id => self.user.id,
        :message => "was teleported by <a href=\"#{self.pmog_host}/users/#{self.user.login}\">#{self.user.login}'s</a> Abundant Portal on <a href=\"http://#{Url.host(self.location.url)}\">#{Url.host(self.location.url)}</a>",
        :details => "You built this portal to <a href=\"#{self.destination.url}\">#{self.destination.url}</a> on #{self.created_at.to_s}. +2CP, +2DP!"

    ### STANDARD ###
    else
      Event.record :context => 'portal_used',
        :user_id => current_user.id,
        :recipient_id => self.user.id,
        :message => "was teleported by <a href=\"#{self.pmog_host}/users/#{self.user.login}\">#{self.user.login}'s</a> Portal on <a href=\"http://#{Url.host(self.location.url)}\">#{Url.host(self.location.url)}</a>",
        :details => "You built this portal to <a href=\"#{self.destination.url}\">#{self.destination.url}</a> on #{self.created_at.to_s}. +2CP!"
    end

    if current_user != self.user
      # Also reward the portal taker now that we don't give DP for surfing
      current_user.reward_datapoints(GameSetting.value("DP Per Portal").to_i)
    end

    # deplete the portal last so we don't destroy anything we need
    deplete
  end

  def calculate_average_rating
    self.average_rating = ratings.average('score', :conditions => ['rateable_id = ?', self.id]).to_i
    save
  end

  # Consistency with other classes
  def is_nsfw?
    self.nsfw
  end

  def to_json_overlay(extra_args = {})
    @hash = Hash[
      :id => id,
      :avatar => avatar_path_for_user(:user => user, :size => 'tiny'),
      :user => user.login,
      :title => title,
      :average_rating => average_rating,
      :nsfw => is_nsfw?,
      :location_url => location.url,
      :destination_url => (destination.nil? ? '' : destination.url),
      :give_dp => abundant
     ]

    @hash.merge(extra_args).to_json
  end

  class << self
    def create_and_deposit(current_user, params)

      raise BlankParams if params[:portal].nil?

      # first, figure out locations
      begin
        #@location = Location.find(params[:location_id])
        @location = Location.find_or_initialize_by_url( Url.normalise(params[:portal][:origin]) )
      rescue ActiveRecord::RecordNotFound
        raise Location::LocationNotFound
      end

      raise BlankDestination if params[:portal][:destination].blank?

      @destination = Location.find_or_initialize_by_url( Url.normalise(params[:portal][:destination]) )
      raise Location::InvalidLocation unless @destination.save

      raise BlankHint if params[:portal][:title].blank?

      raise User::InventoryError.new("You do not have any Portals to deploy.") unless current_user.inventory.portals >= 1

      # this needs to outscope the upgrades checks
      portal_data = {
        :title => params[:portal][:title],
        :nsfw => params[:portal][:nsfw],
        :location_id => @location.id,
        :destination_id => @destination.id,
        :charges => Tool.cached_single(:portals).charges,
        :average_rating => current_user.average_rating,
        :abundant => false
      }

      if params[:upgrade]
        total_ping_cost = 0

        if(params[:upgrade][:give_dp] && params[:upgrade][:give_dp].to_bool)
          abundant_settings = Upgrade.cached_single('give_dp')
          raise User::InsufficientExperienceError.new("You must be a level #{abundant_settings.level} Seer to make your portal give DP") if(current_user.levels[:seer] < abundant_settings.level)
          raise User::InsufficientPingsError.new("You don't have enough pings to create an Abundant Portal!") if current_user.available_pings < abundant_settings.ping_cost
          total_ping_cost += Upgrade.cached_single('give_dp').ping_cost
          portal_data[:abundant] = true
        end

        raise User::InsufficientPingsError if current_user.available_pings < total_ping_cost
      end


      @deployed_portal = current_user.portals.create portal_data

      # this should never get raised, but i'm leaving it here anyway
      raise InvalidPortal unless @deployed_portal.valid?

      ### VALIDATION COMPLETE ###

      current_user.inventory.withdraw :portals

      if portal_data[:abundant]
        current_user.upgrade_uses.reward :give_dp
        current_user.deduct_pings(Upgrade.cached_single("give_dp").ping_cost)

        Event.record :context => 'abundant_portal_deployed',
          :user_id => current_user.id,
          :message => "just opened up an Abundant Portal on <a href=\"http://#{Url.host(@deployed_portal.location.url)}\">#{Url.host(@deployed_portal.location.url)}</a>"
      else
        current_user.tool_uses.reward :portals

        Event.record :context => 'portal_deployed',
          :user_id => current_user.id,
          :message => "just opened up a Portal on <a href=\"http://#{Url.host(@deployed_portal.location.url)}\">#{Url.host(@deployed_portal.location.url)}</a>"
      end

      @deployed_portal

    rescue InvalidPortal
      current_user.inventory.deposit :portals
      raise
    end

    # Find a pseudo-random portal. We don't use RAND() as it's not kind on the database, and we reject
    # any portals that start from PMOG, since they are most likely private as well as any portals you have
    # already taken  - duncan 7/10/08
    def find_first_random_and_appropriate_for(current_user)
      rating = current_user.preferences.get('PMOG Portal Content Quality Threshold').value rescue '3'
      nsfw = current_user.preferences.get('Allow NSFW Content').value.to_bool rescue false
      nsfw ? nsfw_condition = '' : nsfw_condition = 'AND nsfw = 0'
      portals = Portal.find( :all, :conditions => "average_rating >= #{rating} #{nsfw_condition}", :order => 'created_at DESC', :limit => 100 )
      portal = portals.reject{ |p|
        p.location.nil? ||
        p.location.is_pmog_url ||
        p.dismissals.dismissed_by?(current_user) ||
        current_user.daily_domains.recently_visited?(p.location) ||
        p.user_ids.include?(current_user.id)
      }.rand
    end

    # Track the jump to the portal starting point as a tool use, so that
    # we can see how many jaunts are being taken
    def record_jaunt(current_user)
#      current_user.tool_uses.reward :portals, :usage_type => 'jaunt'
      current_user.misc_action_uses.reward :jaunt
    end
  end

  protected
  def before_create
    self.id = create_uuid
  end

  def after_create
    rate(user)
  end
end
