# == Schema Information
# Schema version: 20081220201004
#
# Table name: missions
#
#  id              :string(36)    default(""), not null, primary key
#  name            :string(255)
#  url_name        :string(255)
#  description     :text          not null
#  branches_count  :integer(11)   default(0)
#  created_at      :datetime
#  updated_at      :datetime
#  user_id         :string(36)
#  association     :string(255)
#  average_rating  :integer(11)   default(0)
#  nsfw            :boolean(1)
#  pmog_mission    :boolean(1)
#  is_active       :boolean(1)
#  total_ratings   :integer(11)   default(0)
#  minimum_level   :integer(11)   default(1)
#  cached_tag_list :string(255)
#

class Mission < ActiveRecord::Base
  include FirstValidScope
  # The number of missions to show per the missions view
  @@limit_per_page = 50
  cattr_reader :limit_per_page

  acts_as_cached

  # Addition of acts_as_commentable 01/18/2008 marc@gamelayers.com
  acts_as_commentable

  # Addition of acts_as_voteable 02/11/2008 marc@gamelayers.com
  acts_as_voteable

  acts_as_favorite

  acts_as_taggable

  # Addition of acts_as_activated for defining mission drafts 03/11/2008 marc@gamelayers.com
  acts_as_activated

  belongs_to :user

  has_many :ratings, :as => :rateable, :dependent => :destroy
  has_many :dismissals, :as => :dismissable, :dependent => :destroy, :extend => DismissableExtension
  has_many :branches, :order => "position", :dependent => :destroy
  has_many :takings, :dependent => :destroy
  has_many :takers, :through => :takings, :source => :user

  #has_and_belongs_to_many :users
  has_many :missionatings
  has_many :users, :through => :missionatings

  # I took the user_id off of the validation below as the form errors on it and shouldn't
  # also, logically the mission will always have the user_id on it because we're creating it that way
  validates_presence_of :name, :description
  validates_associated :branches, :message => '- one or more branch is invalid'
  validates_uniqueness_of :url_name, :case_sensitive => false

  attr_accessor :saving_lightposts

  # Protect internal methods from mass-update.
  attr_accessible :name, :description, :user, :url_name, :minimum_level

  def to_param
    url_name
  end

  def to_json_overlay(extra_args = {})
    Hash[
      :id => self.id,
      :author => self.user.login,
    ].merge(extra_args).to_json
  end

  # This is needed to store the user who made the mission into the search index.
  def author_name
    return self.user.login
  end

  def should_validate_branch_count?
    saving_lightposts
  end

  def validate
    # check to make sure that the minimum_level input is not greater than 19 nor higher than the users level
    errors.add(:minimum_level, "cannot be higher than your current level") unless self.user && self.minimum_level.to_i <= self.user.current_level
    errors.add(:minimum_level, "cannot be higher than 19") unless self.minimum_level.to_i <= 19

    if saving_lightposts
      if self.branches.count < 4
        errors.add(:mission, ' must have at least 4 lightposts')
      end

      self.branches.each do |branch|
        if branch.description == 'Please enter a description for this lightpost' or branch.description.empty?
          errors.add_to_base(branch.location.url + ' needs a valid description')
        end
      end
    end
    errors.empty?
  end

  def self.latest( limit = 5, sort='missions.created_at DESC', allow_nsfw = false )
    get_cache( "latest_missions_#{limit}_#{allow_nsfw}" ) {
      with_scope( nsfw_scope(allow_nsfw) ) do
        self.non_pmog_missions do
          self.find( :all, :include => {:user => :assets}, :order => sort, :limit => limit )
        end
      end
    }
  end

  # Find all missions and group them by their association/tag
  def self.find_all_in_groups(allow_nsfw = true)
    # This is too big to fit in the cache :(
    #get_cache( "all_in_groups_#{allow_nsfw}" ) {
      missions = { :benefactor => [], :vigilante => [], :pathmaker => [], :seer => [], :riveter => [], :grenadier => [], :bedouin => [], :destroyer => [] }
      with_scope( nsfw_scope(allow_nsfw) ) do
        self.non_pmog_missions do
          find_missions(:all, :order => 'created_at DESC' ).each do |mission|
            missions.each do |pmog_class|
              if mission.association and mission.association.downcase == pmog_class[0].to_s
                missions[ pmog_class[0] ] << mission
                next
            end
          end
          end
        end

      end

      with_scope( nsfw_scope(allow_nsfw) ) do
        missions[:newest] = self.find( :all, :order => 'created_at DESC' )
      end

      with_scope( nsfw_scope(allow_nsfw) ) do
        missions[:shoat] = self.find( :all, :conditions => 'association IS NULL', :order => 'created_at DESC' )
      end

      with_scope( nsfw_scope(allow_nsfw) ) do
        missions[:highest_rated] = self.find_top(nil, nil, nil)
      end
      missions
    #}
  end

  # Find all missions by +association+, i.e. those tagged with seer, or pathmaker
  def self.find_all_in_association(params, sort, current_user, allow_nsfw = true)
    with_scope( nsfw_scope(allow_nsfw) ) do
      @missions = Mission.find( :all,
                                    :include => [ :tags ],
                                    :conditions => [ 'association = ? and minimum_level <= ?', params[:id], current_user.current_level + 2],
                                    :order => sort )
    end
  end

  def self.find_all_by_shoat(params, sort, current_user, allow_nsfw = true)
    with_scope( nsfw_scope(allow_nsfw) ) do
      @missions = Mission.find( :all,
                                    :include => [ :tags ],
                                    :conditions => [ 'association IS NULL and minimum_level <= ?', current_user.current_level + 2 ],
                                    :order => sort )
    end
  end

  # Find a mission, for display on the missions/show page, mostly
  def self.cached_find_by_url_name(name)
    get_cache(name) {
      find( :first, :conditions => { :url_name => name }, :include => [ {:branches => :location}, {:user => :assets}, :tags ], :order => 'branches.position asc', :group => 'missions.id, branches.id' ) or raise ActiveRecord::RecordNotFound
    }
  end

  # Deprecated, but supposedly intelligent finder for missions
  def self.find_with_associated( url_name )
    # This might seem counter intuitive, executing a query to see if the mission has nested associations (NPCs, or Birdbots)
    # but it's useful in allowing us to choose the right query, to cut down on the number of queries run later.
    mission = Mission.find_by_sql [ 'select branches_npcs.* from branches_npcs, branches, missions where branches_npcs.branch_id = branches.id and branches.mission_id = missions.id and missions.url_name = ?', url_name ]

    if mission.empty?
      # Just eager load the basics
      Mission.find( :first, :conditions => { :url_name => url_name}, :include => [ :branches, :user, :tags ], :order => 'branches.position asc', :group => 'missions.id, branches.id' )
    else
      # This seems to load the mission and its branches in the least number of queries possible.
      # For some reason, even though we eager load npcs and bird_bots, accessing them still fires off
      # an extra query, which I can't eliminate at this stage. We'll cache this at some point, regardless.
      Mission.find( :first, :conditions => { :url_name => url_name}, :include => [ { :branches => [ :children, :parent ] }, { :branches => :npcs }, { :branches => :bird_bots }, :user, :tags ], :order => 'branches.position asc', :group => 'missions.id, branches.id' )
    end
  end

  def self.find_first_random_and_appropriate_for(current_user)
    missions = Mission.find(:all, :conditions => {:nsfw => 0}, :include => :takers, :order => 'average_rating DESC', :limit => 100)
    missions.reject{ |m|
      m.takers.include?(current_user) ||
      m.dismissals.dismissed_by?(current_user) ||
      current_user.preferences.falls_below_quality_threshold(m) ||
      current_user.preferences.falls_outside_nsfw_threshold(m)
    }.rand
  end


  # Deprecated, find all missions that are not tagged
  def self.find_untagged
    find( :all, :conditions => 'tags.name is null', :include => :tags, :order => 'missions.created_at DESC' )
  end

  # The mission creator earns 10 dp for every user who takes their mission
  def reward_creator(user)
    # Per http://pmog.devjavu.com/ticket/780 we're going to reward players based
    # on the rating of the mission
    unless self.users.include? user or user == self.user
      case self.average_rating
      when 0 then self.user.reward_datapoints(4)
      when 1 then self.user.reward_datapoints(4)
      when 2 then self.user.reward_datapoints(6)
      when 3 then self.user.reward_datapoints(8)
      when 4 then self.user.reward_datapoints(10)
      when 5 then self.user.reward_datapoints(12)
      end
    end
    self.user.misc_action_uses.reward :mission_taken
    self.user.reward_pings Ping.value('Mission Taken')

    if user != self.user
      # Also reward the mission taker now that we don't give DP for surfing
      user.reward_datapoints(GameSetting.value("DP Per Mission").to_i * branches.count)
    end
  end

  # Simple cached finder
  def self.cached_find_by_id(id)
    get_cache( "find_by_id_#{id}") {
      Mission.find( :first, :conditions => { :id => id }, :include => :user )
    }
  end

  def before_create
    self.id = create_uuid
    self.url_name = unique_url_name(name)
    self.minimum_level = 1 if self.minimum_level.blank?
  end

  # Generate a unique name for this mission, for use in the url
  def unique_url_name( name )
    url_name = "#{name.downcase.gsub(/\s+/, '_').gsub(/[^a-zA-Z0-9_]+/, '')}"
    existing = Mission.count_with_inactive( :conditions => [ 'url_name = ?', url_name ] )
    while existing > 0
      url_name += '_'
      existing = Mission.count_with_inactive( :conditions => [ 'url_name = ?', url_name ] )
    end
    url_name
  end

  def calculate_average_rating
    self.average_rating = ratings.average('score', :conditions => ['rateable_id = ?', self.id]).to_i
    save
  end

  def calculate_total_ratings
    self.total_ratings = ratings.count
    save
  end

  def self.find_top(params, current_user, sort = 'missions.created_at DESC', allow_nsfw = true)
    with_scope( nsfw_scope(allow_nsfw) ) do
      @result = Mission.find :all,
                             :include => params[:include],
                             :conditions => params[:conditions],
                             :group => 'missions.id HAVING missions.total_ratings > 10 AND missions.average_rating >= 4',
                             :order => params[:order],
                             :limit => params[:limit]
    end
    return @result
  end

  def self.non_pmog_missions(*args)
    with_scope :find => { :conditions => [ 'pmog_mission = ?', 0 ], :include => [ { :user => :assets } ] } do
      yield
    end
  end

  def self.pmog_missions(*args)
    with_scope :find => { :conditions => [ 'pmog_mission = ?', 1 ], :include => [ { :user => :assets } ] } do
      yield
    end
  end

  def self.find_missions(*args)
    non_pmog_missions do
      find(*args)
    end
  end

  def self.method_missing(method, *args, &block)
    if method.to_s =~ /^find_(all_)?missions_by/
      non_pmog_missions do
        super(method.to_s.sub('missions_', ''), *args, &block)
      end
    else
      super(method, *args, &block)
    end
  end

  def is_nsfw?
    return self.nsfw
  end

  # This is a convenience method to check if the mission is a PMOG-related mission
  def pmog_mission?
    self.pmog_mission
  end

  def make_pmog!
    unless self.pmog_mission?
      self.pmog_mission = true
    end
  end

  def unmake_pmog!
    unless !self.pmog_mission?
      self.pmog_mission = false
    end
  end

  # Adds a dismissed mission record for the user provided
  # Then clears the branch cache to ensure they don't get
  # a cached overlay of a dismissed mission.
  def dismiss(user)
    unless dismissals.dismissed_by? user
      dismissals.dismiss user
      clear_branch_cache
    end
  end

  # Clears the branch cache of the current mission instance.
  # Used when dismissing missions
  def clear_branch_cache
    branches.each do |branch|
      Url.variants(branch.location.url).each do |url|
        @location = Location.find( :first, :conditions => { :url => url} )
        Branch.expire_cache("nearby:#{@location.url}") unless @location.nil?
      end
    end
  end
  ########################################################
  # DRYing up the checks for the mission generator       #
  ########################################################

  # This will check to see if the mission has been tested
  def is_tested?
    self.users.include?(self.user)
  end

  # This will check to see if the mission has the requisite number of branches
  def has_branches?
    self.branches.length >= 4
  end

  # This will check if the mission has a name and description
  def has_info?
    !self.name.nil? and self.name.length >= 1 and !self.description.nil? and self.description.length >= 1
  end

  # Publish the mission and update the timestamp for the created_at
  def publish
    # calculate the puzzle summary field
    puzzled = false
    self.branches.each do |branch|
      unless branch.puzzle.nil?
        puzzled = true
        break
      end
    end
    self.puzzle = puzzled
    self.save


    unless self.is_active
      # NOTE yes this can get called multiple times, there isnt much i can do about that
      # we really dont use this for exact bookeeping, its mostly to ensure you get the levelup message
      # we also don't give out the points for rebuilds (if this mission is already published)
      self.user.misc_action_uses.reward :mission_published
    end

    # Active = publishing. All non-active missions get filtered from the default view.
    self.activate!

    # Set the mission created_at to now so it gets entered as a new mission in the list
    now = Time.now
    self.created_at = now.getutc.to_s(:db)
  end

  # Unpublish the mission.
  def unpublish
    self.users.delete(self.user)

    # NOTE we cant un-reward people, so this is hackish
    # only deduct the points if the mission is actually published to start
    if self.is_active
      self.user.user_level.pathmaker_cp -= MiscAction.cached_single('mission_published').classpoints
      self.user.user_level.save
    end

    self.deactivate!
  end

  # A bit of a...hack perhaps...to make sure that minimum_level can never be nil
  def minimum_level
    if @minimum_level.blank?
      @minimum_level = 1
    end

    @minimum_level
  end

  # Find all drafts for the user provided
  def self.find_all_drafts_for_user(user_id, sort)
    find_with_inactive(:all, :conditions => ['user_id = ? and is_active = ?', user_id, 0], :group => sort)
  end

  # Just a simple stat calculation method. Call it using cache, like this
  # Mission.caches( :average_lightposts_per_mission )
  def self.average_lightposts_per_mission
    counts = Branch.find_by_sql( 'SELECT count(*) AS total FROM branches GROUP BY mission_id' )
    return 0 if counts.empty?
    (counts.sum{ |b| b[:total].to_i }.to_f / counts.size.to_f).round
  end

  class << self
    def completed_this_week
      get_cache('completed_this_week') do
        find(:all, :select => 'COUNT(missionatings.mission_id) AS count, DATE(missionatings.created_at) AS date', :conditions => ['missionatings.created_at BETWEEN ? AND ?', 0.weeks.ago.at_beginning_of_week.to_time, 0.weeks.ago.at_end_of_week.to_time], :joins => 'INNER JOIN missionatings ON missions.id = missionatings.mission_id', :group => 'DATE(missionatings.created_at)', :order => 'DATE(missionatings.created_at) ASC' )
      end
    end

    def completed_last_week
      get_cache('completed_last_week') do
        find(:all, :select => 'COUNT(missionatings.mission_id) AS count, DATE(missionatings.created_at) AS date', :conditions => ['missionatings.created_at BETWEEN ? AND ?', 1.weeks.ago.at_beginning_of_week.to_time, 1.weeks.ago.at_end_of_week.to_time], :joins => 'INNER JOIN missionatings ON missions.id = missionatings.mission_id', :group => 'DATE(missionatings.created_at)', :order => 'DATE(missionatings.created_at) ASC' )
      end
    end

    def completed_all_time
      get_cache('completed_all_time') do
        find(:all, :select => 'COUNT(missionatings.mission_id) AS count, DATE(missionatings.created_at) AS date', :joins => 'INNER JOIN missionatings ON missions.id = missionatings.mission_id', :group => 'DATE(missionatings.created_at)', :order => 'DATE(missionatings.created_at) ASC' )
      end
    end
  end

  # Returns a list of the related (by tag) missions
  # - uses the top 3 tags for this mission
  def related(limit = 3)
    get_cache("related_#{limit}", :ttl => 1.day) do
      related_missions = []
      num_tags = (self.tags.size > limit ? limit: self.tags.size)

      num_tags.times do |i|
        tags = Mission.find_related_tags(self.tags[i])
        tags[0..3].each do |t|
          # Note that find_tagged_with uses 3 tables and a LIKE, which hurts the database,
          # so we use the cached_tag_list and just run a LIKE on that. This might degrade
          # since it executes a full table scan too, but we'll see - duncan 12/12/08
          related_missions << Mission.find(:all, :conditions => ['cached_tag_list LIKE ?', "%#{t.name}%"], :order => 'average_rating DESC', :limit => 5)
        end
      end

      related_missions.flatten.uniq.reject{ |m| m.id == self.id }[0..(limit-1)]
    end
  end

  # A list of Missions taken by +user+
  # - this is often too big for memecached, so we cache only the ids
  #   and use get_caches to cache each mission individually.
  # - note the hack where get_caches doesn't respect disabling memcache
  # - make sure to return an array not a hash if there are no results
  def self.taken(user)
    ids = get_cache("taken_missions_#{user.login}", :ttl => 1.day) do
      missions = Missionating.find( :all,
                                    :conditions => {:user_id => user.id},
                                    :order => 'created_at DESC' )
     valid_missions =  missions.collect{ |m| m.mission }.uniq.reject{ |n| n.nil? }
     valid_missions.collect{ |o| o.id }
    end
    taken_missions = ( ActsAsCached.config[:disabled] ? Mission.find(ids) : Mission.get_caches(ids, :ttl => 1.day) )
    return (taken_missions.empty? ? [] : taken_missions.values)
    #get_cache("taken_#{user.login}", :ttl => 1.day) do
    #   missions = Missionating.find( :all,
    #                                 :conditions => {:user_id => user.id},
    #                                 :order => 'created_at DESC' )
    #   missions.collect{ |m| m.mission }.uniq.reject{ |m| m.nil? }
    #end
  end

  # A list of Missions favourited by +user+
  def self.favourites(user)
    get_cache("favourites_#{user.login}", :ttl => 1.day) do
      missions = Favorite.find( :all,
                                :conditions => ['user_id = ? AND favorable_type = ?', user.id, 'Mission'],
                                :order => 'created_at DESC' )
      missions.collect{ |m| m.favorable }.uniq.reject{ |m| m.nil? }
    end
  end

  # Returns a random, recently created Mission over or above +average_rating+
  def self.recently_created(average_rating = 4)
    get_cache("recently_created_#{average_rating}", :ttl => 1.day) do
      missions = Mission.find(:all, :include => :user, :conditions => ['nsfw = ? AND average_rating >= ?', 0, average_rating], :order => 'created_at DESC', :limit => 5)
      missions.rand
    end
  end

  protected
  # Create the relevant Sql condition for enabling/disabling NSFW content
  def self.nsfw_condition(allow_nsfw = false)
    if allow_nsfw == 'true'
      conditions = nil
    else
      conditions = { :nsfw => 0 }
    end
    conditions
  end

  private

  # Create the scope to use when finding for nsfw
  def self.nsfw_scope(allow_nsfw)
    { :find => { :conditions => self.nsfw_condition(allow_nsfw) } }
  end

  def self.raise_on_illegal_options(options, *option_keys)
    option_keys.each do |option_key|
      if options[option_key]
        raise ArgumentError.new(
          ":#{option_key} is not a valid option to #{calling_method}"
        )
      end
    end
  end
end
