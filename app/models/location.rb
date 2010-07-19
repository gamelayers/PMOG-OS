# == Schema Information
# Schema version: 20081220201004
#
# Table name: locations
#
#  id         :string(36)    default(""), not null, primary key
#  url        :string(255)
#  created_at :datetime
#  updated_at :datetime
#

# Locations are the fundamental web addresses on the web.
require 'url'
class Location < ActiveRecord::Base
  #set_table_name :locations

  PMOG_DOMAINS = [ 'http://pmog.com',
    'http://ext.pmog.com',
    'http://www.pmog.com',
    'http://dev.pmog.com',
    'http://thenethernet.com',
    'http://ext.thenethernet.com',
    'http://www.thenethernet.com',
    'http://dev.thenethernet.com',
    'http://thenether.net',
    'http://ext.thenether.net',
    'http://www.thenether.net',
    'http://dev.thenether.net',
    'http://0.0.0.0:3000',
    'http://localhost:3000',
    'http://hospital.pmog.com'
  ]

  PMOG_USER_DOMAINS = [ 'http://pmog.com/users/',
    'http://ext.pmog.com/users/',
    'http://www.pmog.com/users/',
    'http://dev.pmog.com/users/',
    'http://thenethernet.com/users/',
    'http://ext.thenethernet.com/users/',
    'http://www.thenethernet.com/users/',
    'http://dev.thenethernet.com/users/',
    'http://thenether.net/users/',
    'http://ext.thenether.net/users/',
    'http://www.thenether.net/users/',
    'http://dev.thenether.net/users/',
    'http://0.0.0.0:3000/users/',
    'http://localhost:3000/users/'
  ]

  acts_as_cached
  acts_as_taggable

  has_and_belongs_to_many :npcs, :join_table => 'npcs_locations'
  has_and_belongs_to_many :bird_bots, :join_table => 'bird_bots_locations'
  #belongs_to :tld

  # Possible items to stumble upon on a URL
  @@items = [:mines, :portals, :crates, :giftcards, :branches, :watchdogs]

  has_many :mines
  has_many :portals, :conditions => 'branch_id is null' # we don't want mission portals to show up
  has_many :crates
  has_many :giftcards
  has_many :branches
  has_many :faves
  has_many :watchdogs

  #before_save :update_tld

  # Note that validates_uniqueness_of is not case insensitve
  # as that doesn't use the mysql index or query cache
  validates_uniqueness_of :url
  validates_presence_of :url

  # Splits the url into protocol, host, path, file, query and hash, from http://textsnippets.com/posts/show/523
  # It's somewhat unreliable, though, so I've disabled it for now - duncan 23/11/07
  #validates_format_of :url, :with => /^((http[s]?):\/)?\/?([^:\/\s]+)((\/\w+)*\/)([\w\-\.]+[^#?\s]+)(.*)?(#[\w\-]+)?$/

  # Restricted attributes and included association for JSON output
  cattr_accessor :private_api_fields, :included_api_associations
  @@private_api_fields = []
  @@included_api_associations = [ :tags, :mines, :portals, :crates, :branches ]

  class LocationError < PMOG::PMOGError; end

  class LocationNotFound < LocationError
    def default
      "Location not found.  Please refresh the page or try a new URL."
    end
  end

  class InvalidLocation < LocationError
    def default
      "Sorry, but this type of URL is not supported."
    end
  end

  class ProtectedByPmog < LocationError
    def default
      "Ha - we don't think so!  thenethernet.com is off limits."
    end
  end

  def update_tld
    self.tld = Tld.safe_add(self.url) if self.tld.nil?
  end

  def increment(user_id, ip)
    update_tld
    self.tld.increment(user_id, ip)
  end


  # Is this part of location pmog.com
  def protected_by_pmog?
    get_cache('protected_by_pmog', :ttl => 1.week) do
      protected_by_pmog = false

      # Ugh, shouldn't be hard coded, maybe we could use request.host_with_port here?
      PMOG_DOMAINS.each do |host|
        protected_by_pmog = true if self.url =~ /^#{host}.*/
      end
      protected_by_pmog
    end
  end

  # Is this location part of the minefield learning area on pmog.com?
  def minefield?
    get_cache('minefield?', :ttl => 1.week) do
      minefield = false
      PMOG_DOMAINS.each do |host|
        minefield = true if self.url =~ /^#{host}\/learn\/mines/
      end
      minefield
    end
  end

  # Is this location a profile page on pmog.com?
  # If it is, return the username of the relevent person, otherwise return nil
  def check_for_pmog_profile_page
    @profile_user = nil
    if is_user_profile
      @profile_user = get_user_from_url
    end

    return @profile_user
  end

  # This is a simple boolean check for items placed on PMOG profile pages that are hidden to everyone but their owners.
  def user_specific_item(user)
    get_cache("user_specific_item_for_#{user}", :ttl => 1.day) do
      is_user_profile and not is_users_profile(user.login)
    end
  end

  # Very simple finder with no eager loading
  def self.find_with_nothing(location_id)
    get_cache( 'id_' + location_id.to_s ) { find(location_id) }
  end

  def validate
    errors.add(:url, 'This url is invalid') if Url.unsupported_format?(url)
  rescue URI::InvalidURIError
    errors.add(:url, 'This url is invalid')
  end

  def before_create
    self.id = create_uuid
  end

  # This will return a boolean if the url of the current location object is a pmog url
  def is_pmog_url
    PMOG_DOMAINS.each do |host|
      return true if self.url =~ /#{host}.+/
    end
    false
  end

  # Determines if the current url is a user profile in general, not a specific user profile url
  # - regex updated to be stricter, should prevent user message pages from being mined too - duncan 28/01/09
  def is_user_profile()
    PMOG_USER_DOMAINS.each do |host|
      #return true if self.url =~ /#{host}.+/
      return true if self.url =~ /#{host}[0-9a-zA-Z_-]+\/?$/
    end
    false
  end

  # Determines if the current url is a specific users profile url. Requires the user login to be passed in.
  def is_users_profile(login)
    # immediately skip out if we aren't a real user profile
    return false unless is_user_profile

    # return true if the 4th pair of //s has the user's name between them
    url_login = get_user_from_url
    # normalize case, since we do for the actual logins
    return true if url_login && url_login.downcase == login.downcase

    return false
  end

  # Returns the # of users who hit the relevant TLD
  def visitor_count(period)
    get_cache("visitor_count_#{period}", :ttl => 1.day) do
      domain_url = 'http://' + Url.caches(:domain, :with => self.url)
      domain = Location.caches( :find_or_create_by_url, :with => domain_url )
      DailyDomain.count(:conditions => {:location_id => domain.id, :created_on => Date.send(period)})
    end
  end

  # This returns the user login from the profile url. I didn't want to double iterate
  # when determining the host so this should only be called after you know that this is a
  # user profile url
  def get_user_from_url
    url_parts = self.url.split('/') rescue nil
    return url_parts[4]
  end

  # Do a quick query to see if there are any objects on this location's URL
  def is_interesting?
    found = 0
    current = 0

    while found == 0 and current < @@items.length
      # puts "Checking for #{@@items[current]}"
      found += send(@@items[current]).count
      current += 1
    end

    return found > 0
  end
end
