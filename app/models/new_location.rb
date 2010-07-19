# == Schema Information
# Schema version: 20081220201004
#
# Table name: locations
#
# Locations are the fundamental web addresses on the web.
#
#

require 'url'
require 'digest/sha1'

class Location < HyperactiveResource
  self.site = "http://nowhere.gamelayers.com"

  def self.belongs_to(clz)
    self.belong_tos << clz
  end

  def self.has_many(clz, args=nil)
    self.has_manys[clz] = args
  end

  def self.column(name, ctype)
    self.columns << name
  end

  column :id, :text
  column :url, :text
  column :tld_id, :integer

  belongs_to :tld

  acts_as_cached

  MAGIC_HASH = "PMOG_OR_NETHERNET"

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
    'http://hospital.pmog.com',
    'http://support.thenethernet.com',
    'http://support.pmog.com'
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

  has_many :mines
  has_many :portals, :conditions => 'branch_id is null' # we don't want mission portals to show up
  has_many :crates
  has_many :giftcards
  has_many :branches
  has_many :faves
  has_many :watchdogs

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

  class LocationCanOnlyUseFindByURL < LocationError
    def default
      "You can only use find_by_url for locations"
    end
  end

  def increment(user, ip=nil)
    self.tld.increment(user, ip)
  end

  def save # don't save
    return false if !valid?

    before_save
    after_save

    return true
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

  def validate
    errors.add(:url, 'This url is invalid') if self.url.nil? or Url.unsupported_format?(self.url)
  rescue URI::InvalidURIError
    errors.add(:url, 'This url is invalid')
  end

  def self.find(which, *args)
    raise LocationCanOnlyUseFindByURL
  end

  def self.find_or_create_by_url(url)
    Location.create(:url => url)
  end

  def self.find_by_url(url)
    self.find_or_create_by_url(url)
  end

  def before_save
    url = self.url + MAGIC_HASH
    url.strip!
    url.downcase!
    self.id = Digest::SHA1.hexdigest(url)
    #puts "SHA1: #{url} => #{self.id}"

    if self.tld.nil?
      self.tld = Tld.safe_add(self.url)
    end
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
end
