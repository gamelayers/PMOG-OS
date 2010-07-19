# == Schema Information
# Schema version: 20081220201004
#
# Table name: badges
#
#  id          :string(36)    default(""), not null, primary key
#  name        :string(255)   
#  description :string(255)   
#  created_at  :datetime      
#  updated_at  :datetime      
#  group_id    :string(36)    
#  url_name    :string(255)   not null
#

# Users earn badges to meeting the requirements set within them, like using a tool a certain
# number of times, or visiting a given website repeatedly over a set period of time. Badge.grant_all 
# should be run hourly from cron or Badge.award(badge_name) will award a specific badge
#
# Another approach might be to award all the easy to calculate badges more often, such as 
# tool usage or missions taken badges. Then award all the harder to get badges, based on x 
# hits in y period on a slower scale.
class Badge < ActiveRecord::Base
  acts_as_cached

  has_many :badgings
  has_many :users, :through => :badgings

  has_and_belongs_to_many :locations

  validates_presence_of :name, :description, :image
  acts_as_groupable
  
  # Find the next sequential badge
  def next
    get_cache( "next_#{id}", :ttl => 1.week ) { self.class.find(:first, :conditions => ['name > ?', name], :order => 'name ASC') }
  end
  
  # Find the previous sequential badge
  def prev
    get_cache( "prev_#{id}", :ttl => 1.week ) { self.class.find(:first, :conditions => [' name < ?', name], :order => 'name DESC') }
  end

  # Convenience method to get the group name that the badge instance is associated with.
  def group_name
    Group.find_by_id(self.group_id).name 
  end

  def inactive?
    ! self.active
  end

  # Picks a random badge
  def self.random
    get_cache('random', :ttl => 1.day) do
      Badge.find(:first, :order => 'RAND()')
    end
  end
  
  # Returns a random badge that this +user+ has not yet unlocked
  def self.random_unearned(user)
    get_cache( "random_unearned_#{user.login}", :ttl => 1.week ) do 
      Badge.find(:all).reject{ |b| user.badges.include? b }.rand
    end
  end
  
  # Attempt to award all the badges to a single user. Run via a bj process
  # Doesn't award the alpah or beta badges, though, those are run separately
  # using Badge.award 'alpha_user'
  def self.grant_all_to(user)
    @user = user
    self.methods.reject{ |method| method !~ /^award_.*/ }.sort.each do |method|
      next if [ 'award_alpha_user', 'award_beta_user' ].include? method
      self.send(method)
    end
    @user.save(false) # do the save here, so that we only save once
  end
    
  # Check if +user+ has earned a specific badge tied to +location+
  def self.check(user, location)
    @user = user
    # Find the relevant badge and munge the badge name into a method name and call it
    self.slave_setup do
      @badge = Badge.find( :first, :joins => "INNER JOIN badges_locations ON badges.id = badges_locations.badge_id", :conditions => [ "badges_locations.location_id = ?", location.id ] )
    end

    unless @badge.nil?
      method = 'award_' + @badge.url_name.gsub('-', '_')
      self.send(method)
      @user.save(false)
    end
  end

  # Award a specific badge
  def self.award(badge_name, user = nil)
    @user = user
    send( 'award_' + badge_name.to_s)
    @user.save(false)
  end

  # Constructs an image filename from the badge name
  def image
    create_permalink(self.name) + ".png"
  end

  # UUID creation
  def before_create
    self.id = create_uuid

    # Um, yeah. So this is because I want migrations before the introduction
    # of the url_name column to still work. It's an ungodly hack, really. So sorry..
    self.url_name = create_permalink(name) if self.attributes.include? 'url_name'
  end
  
  # For use with 99% of the tool use badges, this gets your tool usage count 
  # for any given +tool+ from the database replica
  def self.slaved_tool_count_for(user, tool)
    self.slave_setup do
      user.tool_uses.count( :all, :conditions => { :tool_id => tool.id, :usage_type => 'tool' } )
    end
  end
  
  protected
  # Called by each award when it's determined a user should be awarded the badge
  def self.process_award(user, badge)
    return if user.nil? or badge.nil?
    return if user.login == 'pmog'

#    @pmog_user ||= User.find_by_email('self@pmog.com')
#
#    Message.create(
#      :title => "Badge unlocked!", 
#      :body => "You just unlocked the <a href='http://thenethernet.com/guide/badges/#{badge.url_name}'>#{badge.name}</a> badge!", 
#      :user => @pmog_user,
#      :recipient => user
#    )

    Event.record :context => "badge_unlocked",
      :user_id => user.id,
      :recipient_id => user.id,
      :message => "just unlocked the <a href=\"#{user.pmog_host}/guide/badges/#{badge.url_name}\">#{badge.name}</a> badge"

    user.badges << badge
  end
  
  
  # WEB BROWSING BADGES
  
  
  # For players that visit 100 URLs over a 24 hour period.
  def self.award_torch
    @torch_badge ||= Badge.caches(:find_by_name, :with => 'Torch')

    return if @user.badges.include? @torch_badge || @torch_badge.inactive?
    
    total_hits = 0
    
    self.slave_setup do
      @hits = DailyDomain.find( :all, :conditions => { :user_id => @user.id }, :group => 'created_on, location_id' )
    end
    @hits.collect{ |hit| total_hits += hit.hits }
    
    if total_hits >= 100
      process_award @user, @torch_badge
    end
  end
  
  # For players who read Boing Boing every day they're logged on, for 7 contiguous days
  def self.award_bounce_bounce
    @boing_boing_badge ||= Badge.caches(:find_by_name, :with => 'Bounce Bounce')
    @boing_boing ||= @boing_boing_badge.locations.first
    start_date = (Date.today - 6).to_time.to_s(:db) # -6 as we're including today
    end_date = Date.today.to_time.to_s(:db)
    
    return if @user.badges.include? @boing_boing_badge || @boing_boing_badge.inactive?

    self.slave_setup do
      @hits = DailyDomain.find( :all, :conditions => [ "user_id = ? AND location_id = ? AND created_on BETWEEN ? AND ?", @user.id, @boing_boing.id, start_date, end_date ], :group => 'created_on' )
    end
    
    if @hits.size >= 7
      process_award @user, @boing_boing_badge
    end
  end
  
  # For players who read Tech Crunch every day they're logged on, for 7 contiguous days.
  def self.award_vc
    @techcrunch_badge ||= Badge.caches(:find_by_name, :with => 'VC')
    @techcrunch ||= @techcrunch_badge.locations.first
    start_date = (Date.today - 6).to_time.to_s(:db)
    end_date = Date.today.to_time.to_s(:db)
    
    return if @user.badges.include? @techcrunch_badge || @techcrunch_badge.inactive?
    
    self.slave_setup do
      @hits = DailyDomain.find( :all, :conditions => [ "user_id = ? AND location_id = ? AND created_on BETWEEN ? AND ?", @user.id, @techcrunch.id, start_date, end_date ], :group => 'created_on' )
    end
    
    if @hits.size >= 7
      process_award @user, @techcrunch_badge
    end
  end
  
  # For players who read xkcd.com once a week for 4 contiguous weeks
  def self.award_science
    @xkcd_badge ||= Badge.caches(:find_by_name, :with => 'Science, It Works Bitches')
    @xkcd ||= @xkcd_badge.locations.first
    start_date = (Date.today - 4.weeks).to_time.to_s(:db)
    end_date = Date.tomorrow.at_midnight.to_s(:db)

    return if @user.badges.include? @xkcd_badge || @xkcd_badge.inactive?

    self.slave_setup do
      @hits = DailyDomain.find( :all, :conditions => [ "user_id = ? AND location_id = ? AND created_on BETWEEN ? AND ?", @user.id, @xkcd.id, start_date, end_date ], :group => 'week' )
    end
    
    if @hits.size >= 4
      process_award @user, @xkcd_badge
    end
  end
  
  # For players who visit xboxliveachievements.com more than twice a week for 4 contiguous weeks.
  # Note that we use count(*) to get the number of distinct visits each week. If we want the total
  # hits per week, then use sum(hits) instead.
  def self.award_achiever
    @achiever_badge ||= Badge.caches(:find_by_name, :with => 'Achiever')
    @achiever_x360 ||= @achiever_badge.locations[0]
    @achiever_live ||= @achiever_badge.locations[1]
    start_date = (Date.today - 27).to_s(:db)
    end_date = Date.today.to_s(:db)
    
    return if @user.badges.include? @achiever_badge || @achiever_badge.inactive?
    
    # Counter for the number of hits
    total_hits = 0
    
    # The number of hits for xbox360achievements.org within the last 4 weeks
    self.slave_setup do
      @x360_hits = DailyDomain.find( :all, :select => "*, count(*) as total, week", :conditions => [ "user_id = ? AND location_id = ? AND created_on BETWEEN ? AND ?", @user.id, @achiever_x360.id, start_date, end_date ], :group => 'week' )
    end
    
    # The number of hits for live.xbox.com within the last 4 weeks
    self.slave_setup do
      @live_hits = DailyDomain.find( :all, :select => "*, count(*) as total, week", :conditions => [ "user_id = ? AND location_id = ? AND created_on BETWEEN ? AND ?", @user.id, @achiever_live.id, start_date, end_date ], :group => 'week' )
    end
    
    # Increment total_hits by one if the number of hits
    # for xbox360achievements.org is 2 or more for each week.
    @x360_hits.each do |hit|
      total_hits += 1 if hit.total.to_i >= 2
    end
    
    # If the user has already earned the badge based on their
    # visits to xbox360achievements.org we don't need to waste cycles
    # on checking for live.xbox.com. Skip to the award :)
    if total_hits < 4
      # Increment total_hits by one if the number of hits
      # for live.xbox.com is 2 or more for each week.
      @live_hits.each do |hit|
        total_hits += 1 if hit.total.to_i >= 2
      end
    end
    
    # Award the badge if the user has met the requisite hits
    if total_hits >= 4
      process_award @user, @achiever_badge
    end
  end
  
  # For players who visit nintendo.com more than twice a week for 4 contiguous weeks.
  def self.award_all_about_me
    @nintendo_badge ||= Badge.caches(:find_by_name, :with => 'All About Mii')
    @nintendo ||= @nintendo_badge.locations.first
    start_date = (Date.today - 27).to_s(:db)
    end_date = Date.today.to_s(:db)
    
    return if @user.badges.include? @nintendo_badge || @nintendo_badge.inactive?
    
    total_hits = 0
    
    self.slave_setup do
      @hits = DailyDomain.find( :all, :select => "*, count(*) as total, week", :conditions => [ "user_id = ? AND location_id = ? AND created_on BETWEEN ? AND ?", @user.id, @nintendo.id, start_date, end_date ], :group => 'week' )
    end
    @hits.each do |hit|
      total_hits += 1 if hit.total.to_i >= 2
    end
    
    if total_hits >= 4
      process_award @user, @nintendo_badge
    end
  end
  
  # For players who yesterday went for 24 hours without using Google, but who were online
  def self.award_indie
    @indie_badge ||= Badge.caches(:find_by_name, :with => 'Indie')
    return if @user.badges.include? @indie_badge || @indie_badge.inactive?

    # Google.com and .co.uk. Add more if required
    @google_com ||= @indie_badge.locations[0]
    @google_co_uk ||= @indie_badge.locations[1]

    # We only check yesterday
    start_date = Date.yesterday.at_midnight.to_s(:db)
    end_date = Date.yesterday.end_of_day.to_s(:db)

    # You must have logged in once
    self.slave_setup do
      @visits = DailyLogIn.find( :all, :conditions => [ "user_id = ? AND created_at BETWEEN ? AND ?", @user.id, start_date, end_date ] )
    end
    
    # If they've logged in at least once...
    if @visits.size > 0
      self.slave_setup do
        @google_com_hits = DailyDomain.find( :all, :conditions => [ "user_id = ? AND location_id = ? AND created_on BETWEEN ? AND ?", @user.id, @google_com.id, start_date, end_date ], :group => 'created_on' )
      end
      self.slave_setup do
        @google_co_uk_hits = DailyDomain.find( :all, :conditions => [ "user_id = ? AND location_id = ? AND created_on BETWEEN ? AND ?", @user.id, @google_co_uk.id, start_date, end_date ], :group => 'created_on' )
      end

      if @google_com_hits.size == 0 && @google_co_uk_hits.size == 0
        process_award @user, @indie_badge
      end
    end
  end

  # 4 facebook.com urls a day four days out of every seven, four weeks in a row.
  def self.award_dorians_darlings
    @badge = Badge.caches(:find_by_name, :with => "Dorian's Darlings")
    return if @user.badges.include? @badge || @badge.inactive?
    
    @location = @badge.locations.first
    
    start_date = 4.weeks.ago.to_time.to_s(:db)
    end_date = Date.today.to_time.to_s(:db)
    
    total_hits = 0
    self.slave_setup do
      @hits = DailyDomain.find( :all, :select => '*, count(*) as total, SUM(hits) AS total_hits, week', :conditions => [ 'user_id = ? AND location_id = ? AND created_on BETWEEN ? AND ?', @user.id, @location.id, start_date, end_date ], :group => 'week' )
    end
    @hits.each do |hit|
      # total is the number of visits per week, so that should be > 4
      # hits is the number of visits per day, so that should be 4 urls for 4 days, i.e. 16
      total_hits += 1 if hit.total.to_i >= 4 and hit.total_hits.to_i >= 16
    end
    
    # 4 weeks in a row
    if total_hits >= 4
      process_award @user, @badge
    end
  end
  
  # 3 myspace.com urls a day, four days out of every seven, four weeks in a row
  def self.award_space_is_the_place
    @badge = Badge.caches(:find_by_name, :with => 'Space is the Place')
    return if @user.badges.include? @badge || @badge.inactive?
    
    @location = @badge.locations.first
    
    start_date = 4.weeks.ago.to_time.to_s(:db)
    end_date = Date.today.to_time.to_s(:db)
    
    total_hits = 0
    self.slave_setup do
      @hits = DailyDomain.find( :all, :select => '*, count(*) as total, SUM(hits) AS total_hits, week', :conditions => [ 'user_id = ? AND location_id = ? AND created_on BETWEEN ? AND ?', @user.id, @location.id, start_date, end_date ], :group => 'week' )
    end
    @hits.each do |hit|
      # total is the number of visits per week, so that should be >= 4
      # hits is the number of visits per day, so that should be 3 urls for 4 days, i.e. 12
      total_hits += 1 if hit.total.to_i >= 4 and hit.total_hits.to_i >= 12
    end
    
    # 4 weeks in a row
    if total_hits >= 4
      process_award @user, @badge
    end
  end


  # 4 youtube.com urls a day, three days each week, four weeks in a row
  def self.award_mesmerized
    @badge = Badge.caches(:find_by_name, :with => 'Mesmerized')
    return if @user.badges.include? @badge || @badge.inactive?
    
    @location = @badge.locations.first
    
    start_date = 4.weeks.ago.to_time.to_s(:db)
    end_date = Date.today.to_time.to_s(:db)
    
    total_hits = 0
    self.slave_setup do
      @hits = DailyDomain.find( :all, :select => '*, count(*) as total, SUM(hits) AS total_hits, week', :conditions => [ 'user_id = ? AND location_id = ? AND created_on BETWEEN ? AND ?', @user.id, @location.id, start_date, end_date ], :group => 'week' )
    end
    @hits.each do |hit|
      # total is the number of visits per week, so that should be >= 3
      # hits is the number of visits per day, so that should be 4 urls for 3 days, i.e. 12
      total_hits += 1 if hit.total.to_i >= 3 and hit.total_hits.to_i >= 12
    end
    
    # 4 weeks in a row
    if total_hits >= 4
      process_award @user, @badge
    end
  end

  # 4 hits at Flickr.com a day, four days a week, four weeks in a row
  def self.award_soul_catcher
    @badge = Badge.caches(:find_by_name, :with => 'Soul Catcher')
    return if @user.badges.include? @badge || @badge.inactive?
    
    @location = @badge.locations.first
    
    start_date = 4.weeks.ago.to_time.to_s(:db)
    end_date = Date.today.to_time.to_s(:db)
    
    total_hits = 0
    self.slave_setup do
      @hits = DailyDomain.find( :all, :select => '*, count(*) as total, SUM(hits) AS total_hits, week', :conditions => [ 'user_id = ? AND location_id = ? AND created_on BETWEEN ? AND ?', @user.id, @location.id, start_date, end_date ], :group => 'week' )
    end
    @hits.each do |hit|
      # total is the number of visits per week, so that should be >= 4
      # hits is the number of visits per day, so that should be 4 urls for 4 days, i.e. 16
      total_hits += 1 if hit.total.to_i >= 4 and hit.total_hits.to_i >= 16
    end
    
    # 4 weeks in a row
    if total_hits >= 4
      process_award @user, @badge
    end
  end

  # Visit io9.com three times a week for a month
  def self.award_take_me_to_your_readers
    @badge = Badge.caches(:find_by_name, :with => 'Take Me to Your Readers')
    return if @user.badges.include? @badge || @badge.inactive?
    
    @location = @badge.locations.first
    
    start_date = 4.weeks.ago.to_time.to_s(:db)
    end_date = Date.today.to_time.to_s(:db)
    
    total_hits = 0
    self.slave_setup do
      @hits = DailyDomain.find( :all, :select => '*, count(*) as total, week', :conditions => [ 'user_id = ? AND location_id = ? AND created_on BETWEEN ? AND ?', @user.id, @location.id, start_date, end_date ], :group => 'week' )
    end
    @hits.each do |hit|
      # total is the number of visits per week, so that should be >= 3
      total_hits += 1 if hit.total.to_i >= 3
    end
    
    # 4 weeks in a row
    if total_hits >= 4
      process_award @user, @badge
    end
  end

  # Visit twitter.com once a week for a month
  def self.award_little_birdie
    @badge = Badge.caches(:find_by_name, :with => 'Little Birdie')
    return if @user.badges.include? @badge || @badge.inactive?
    
    @location = @badge.locations.first
    
    start_date = 4.weeks.ago.to_time.to_s(:db)
    end_date = Date.today.to_time.to_s(:db)
    
    total_hits = 0
    self.slave_setup do
      @hits = DailyDomain.find( :all, :select => '*, count(*) as total, week', :conditions => [ 'user_id = ? AND location_id = ? AND created_on BETWEEN ? AND ?', @user.id, @location.id, start_date, end_date ], :group => 'week' )
    end
    @hits.each do |hit|
      # total is the number of visits per week, so that should be >= 1
      total_hits += 1 if hit.total.to_i >= 1
    end
    
    # 4 weeks in a row
    if total_hits >= 4
      process_award @user, @badge
    end
  end

  # Visit jezebel.com on three days of the week for a month
  def self.award_the_red_tent
    @badge = Badge.caches(:find_by_name, :with => 'The Red Tent')
    return if @user.badges.include? @badge || @badge.inactive?
    
    @location = @badge.locations.first
    
    start_date = 4.weeks.ago.to_time.to_s(:db)
    end_date = Date.today.to_time.to_s(:db)
    
    total_hits = 0
    self.slave_setup do
      @hits = DailyDomain.find( :all, :select => '*, count(*) as total, week', :conditions => [ 'user_id = ? AND location_id = ? AND created_on BETWEEN ? AND ?', @user.id, @location.id, start_date, end_date ], :group => 'week' )
    end
    @hits.each do |hit|
      # total is the number of visits per week, so that should be >= 3
      total_hits += 1 if hit.total.to_i >= 3
    end
    
    # 4 weeks in a row
    if total_hits >= 4
      process_award @user, @badge
    end
  end

  # Visit dopplr.com once a week for a month
  def self.award_flying_with_radar
    @badge = Badge.caches(:find_by_name, :with => 'Flying With Radar')
    return if @user.badges.include? @badge || @badge.inactive?
    
    @location = @badge.locations.first
    
    start_date = 4.weeks.ago.to_time.to_s(:db)
    end_date = Date.today.to_time.to_s(:db)
    
    total_hits = 0
    self.slave_setup do
      @hits = DailyDomain.find( :all, :select => '*, count(*) as total, week', :conditions => [ 'user_id = ? AND location_id = ? AND created_on BETWEEN ? AND ?', @user.id, @location.id, start_date, end_date ], :group => 'week' )
    end
    @hits.each do |hit|
      # total is the number of visits per week, so that should be >= 1
      total_hits += 1 if hit.total.to_i >= 1
    end
    
    # 4 weeks in a row
    if total_hits >= 4
      process_award @user, @badge
    end
  end

  # Visit oreilly.com once a week for a month.
  def self.award_awrooo
    @badge = Badge.caches(:find_by_name, :with => 'Awrooo!')
    return if @user.badges.include? @badge || @badge.inactive?
    
    @location = @badge.locations.first
    
    start_date = 4.weeks.ago.to_time.to_s(:db)
    end_date = Date.today.to_time.to_s(:db)
    
    total_hits = 0
    self.slave_setup do
      @hits = DailyDomain.find( :all, :select => '*, count(*) as total, week', :conditions => [ 'user_id = ? AND location_id = ? AND created_on BETWEEN ? AND ?', @user.id, @location.id, start_date, end_date ], :group => 'week' )
    end
    @hits.each do |hit|
      # total is the number of visits per week, so that should be >= 1
      total_hits += 1 if hit.total.to_i >= 1
    end
    
    # 4 weeks in a row
    if total_hits >= 4
      process_award @user, @badge
    end
  end
  
  # Visit any of kotaku.com, joystiq.com, eurogamer.com or gamespot.com once a week for a month
  def self.award_thumb_buster
    @badge = Badge.caches(:find_by_name, :with => 'Thumb Buster')
    return if @user.badges.include? @badge || @badge.inactive?
    
    @location1 = @badge.locations[0]
    @location2 = @badge.locations[1]
    @location3 = @badge.locations[2]
    @location4 = @badge.locations[3]
    
    start_date = 4.weeks.ago.to_time.to_s(:db)
    end_date = Date.today.to_time.to_s(:db)
    
    total_hits = {}
    [ @location1, @location2, @location3, @location4 ].each do |location|
      self.slave_setup do
        @hits = DailyDomain.find( :all, :select => '*, count(*) as total, week', :conditions => [ 'user_id = ? AND location_id = ? AND created_on BETWEEN ? AND ?', @user.id, location.id, start_date, end_date ], :group => 'week' )
      end
      @hits.each do |hit|
        # total is the number of visits per week, so that should be >= 1
        if hit.total.to_i >= 1
          if total_hits[hit.week.to_i].nil?
            total_hits[hit.week.to_i] = 1
          else
            total_hits[hit.week.to_i] += 1
          end
        end
      end
    end
    
    # Note that total_hits.keys.size is the number of distinct weeks this 
    # user visited any of the relevant domains. Note that total_hits.values 
    # will give you the number of hits each week, if required.
    
    # 4 weeks in a row
    if total_hits.keys.size >= 4
      process_award @user, @badge unless @user.badges.include? @badge
    end
  end

  # Visit http://worldofwarcraft.com, http://thottbot.com, or http://wowinsider.com 3 days a week for two weeks.
  def self.award_web_of_warcraft
    @badge = Badge.caches(:find_by_name, :with => 'Web of Warcraft')
    return if @user.badges.include? @badge || @badge.inactive?
    
    @location1 = @badge.locations[0]
    @location2 = @badge.locations[1]
    @location3 = @badge.locations[2]
    
    start_date = 4.weeks.ago.to_time.to_s(:db)
    end_date = Date.today.to_time.to_s(:db)
    
    total_hits = {}
    [ @location1, @location2, @location3 ].each do |location|
      self.slave_setup do
        @hits = DailyDomain.find( :all, :select => '*, count(*) as total, week', :conditions => [ 'user_id = ? AND location_id = ? AND created_on BETWEEN ? AND ?', @user.id, location.id, start_date, end_date ], :group => 'week' )
      end
      @hits.each do |hit|
        # total is the number of visits per week, so that should be >= 3
        if hit.total.to_i >= 3
          if total_hits[hit.week].nil?
            total_hits[hit.week] = 1
          else
            total_hits[hit.week] += 1
          end
        end
      end
    end
    
    # 2 weeks in a row
    if total_hits.keys.size >= 2
      process_award @user, @badge
    end
  end

  # Badges earned by visiting five times a week for a fortnight
  def self.award_5_days_a_week_for_two_weeks
    [ "KillahOm", "Crowd Control", "Lotus Drinkers", "Dealers", "Better Than Halo 3", "Queen Bee", "Great Beast", "Stop Motion", "Badges. We has them" ].each do |badge_name|
      badge = Badge.caches(:find_by_name, :with => badge_name)
      next if @user.badges.include? badge || @badge.inactive?

      location = badge.locations.first

      start_date = 2.weeks.ago.to_time.to_s(:db)
      end_date = Date.today.to_time.to_s(:db)

      total_hits = 0
      self.slave_setup do
        @hits = DailyDomain.find( :all, :select => '*, count(*) as total, week', :conditions => [ 'user_id = ? AND location_id = ? AND created_on BETWEEN ? AND ?', @user.id, location.id, start_date, end_date ], :group => 'week' )
      end
      @hits.each do |hit|
        # total is the number of visits per week, so that should be more than 5
        total_hits += 1 if hit.total.to_i >= 5
      end

      # 2 weeks in a row
      if total_hits >= 2
        process_award @user, badge
      end
    end
  end

  # Badges earned by visiting twice a week for a fortnight
  def self.award_2_days_a_week_for_two_weeks
    [ "Fun Theory" ].each do |badge_name|
      badge = Badge.caches(:find_by_name, :with => badge_name)
      next if @user.badges.include? badge || @badge.inactive?

      location = badge.locations.first

      start_date = 2.weeks.ago.to_time.to_s(:db)
      end_date = Date.today.to_time.to_s(:db)

      total_hits = 0
      self.slave_setup do
        @hits = DailyDomain.find( :all, :select => '*, count(*) as total, week', :conditions => [ 'user_id = ? AND location_id = ? AND created_on BETWEEN ? AND ?', @user.id, location.id, start_date, end_date ], :group => 'week' )
      end
      @hits.each do |hit|
        # total is the number of visits per week, so that should be more than 2
        total_hits += 1 if hit.total.to_i >= 2
      end

      # 2 weeks in a row
      if total_hits >= 2
        process_award @user, badge
      end
    end
  end

  # Yes, I know this is horrible, horrible code duplication, I 
  # just don't have the time to fix it right now. When Badges 2.0
  # kicks in, though, it'll be much, much better.
  # Badges earned by visiting three times a week for a fortnight
  def self.award_3_days_a_week_for_two_weeks
    [ "Champion" ].each do |badge_name, url|
      badge = Badge.caches(:find_by_name, :with => badge_name)
      next if @user.badges.include? badge || @badge.inactive?

      location = badge.locations.first

      start_date = 2.weeks.ago.to_time.to_s(:db)
      end_date = Date.today.to_time.to_s(:db)

      total_hits = 0
      self.slave_setup do
        @hits = DailyDomain.find( :all, :select => '*, count(*) as total, week', :conditions => [ 'user_id = ? AND location_id = ? AND created_on BETWEEN ? AND ?', @user.id, location.id, start_date, end_date ], :group => 'week' )
      end
      @hits.each do |hit|
        # total is the number of visits per week, so that should be more than 3
        total_hits += 1 if hit.total.to_i >= 3
      end

      # 2 weeks in a row
      if total_hits >= 2
        process_award @user, badge
      end
    end
  end
  
  
  # TOOL USAGE BADGES
  
  
  # For players who visit less than 10 sites in 7 days (but who ARE online during each of those 7 days)
  def self.award_snowglobe
    @snowglobe_badge ||= Badge.caches(:find_by_name, :with => 'Snowglobe')

    return if @user.badges.include? @snowglobe_badge || @snowglobe_badge.inactive?

    start_date = (Date.today - 6).to_time.to_s(:db)
    end_date = Date.today.end_of_day.to_time.to_s(:db)
    self.slave_setup do
      @hits = DailyDomain.find( :all, :conditions => [ "user_id = ? AND created_on BETWEEN ? AND ?", @user.id, start_date, end_date ], :group => "created_on, location_id" )
    end

    if @hits.size < 10
      # Need to check if they were online for those 7 days, though
      self.slave_setup do
        @visits = DailyLogIn.find( :all, :conditions => [ "user_id = ? AND created_at BETWEEN ? AND ?", @user.id, start_date, end_date ] )
      end
      if @visits.size == 7
        process_award @user, @snowglobe_badge
      end
    end
  end
  
  # More than 8 quests complete
  def self.award_fellow_traveller
    @fellow_traveller_badge ||= Badge.caches(:find_by_name, :with => 'Fellow Traveller')

    return if @user.badges.include? @fellow_traveller_badge || @fellow_traveller_badge.inactive?
    
    if @user.missions.completed.size > 8
      process_award @user, @fellow_traveller_badge
    end
  end
  
  # For players who use more than 250 St. Nicks.
  def self.award_little_sister
    tool = Tool.cached_single( 'st_nicks' )
    @little_sister_badge ||= Badge.caches(:find_by_name, :with => 'Little Sister')

    return if @user.badges.include? @little_sister_badge || @little_sister_badge.inactive?

    if slaved_tool_count_for(@user, tool) > 250
      process_award @user, @little_sister_badge
    end
  end
  
  # For players who use more then 500 St. Nicks.
  def self.award_avenger
    tool = Tool.cached_single( 'st_nicks' )
    @avenger_badge ||= Badge.caches(:find_by_name, :with => 'Avenger')

    return if @user.badges.include? @avenger_badge || @avenger_badge.inactive?
    
    if slaved_tool_count_for(@user, tool) > 500
      process_award @user, @avenger_badge
    end
  end
  
  # For players who use more then 1500 St. Nicks.
  def self.award_good_doctor
    tool = Tool.cached_single( 'st_nicks' )
    @good_doctor_badge ||= Badge.caches(:find_by_name, :with => 'Good Doctor')

    return if @user.badges.include? @good_doctor_badge || @good_doctor_badge.inactive?
    
    if slaved_tool_count_for(@user, tool) > 1500
      process_award @user, @good_doctor_badge
    end
  end
  
  # For players who use more than 250 mines
  def self.award_normandy
    tool = Tool.cached_single( 'mines' )
    @normandy_badge ||= Badge.caches(:find_by_name, :with => 'Normandy')

    return if @user.badges.include? @normandy_badge || @normandy_badge.inactive?
    
    if slaved_tool_count_for(@user, tool) > 250
      process_award @user, @normandy_badge
    end
  end
  
  # For players who use more than 500 mines
  def self.award_all_fired
    tool = Tool.cached_single( 'mines' )
    @all_fired_badge ||= Badge.caches(:find_by_name, :with => 'All-Fired')

    return if @user.badges.include? @all_fired_badge || @all_fired_badge.inactive?
    
    if slaved_tool_count_for(@user, tool) > 500
      process_award @user, @all_fired_badge
    end
  end
  
  # For players who use more than 1500 mines
  def self.award_hell_fire
    tool = Tool.cached_single( 'mines' )
    @hell_fire_badge ||= Badge.caches(:find_by_name, :with => 'Hell Fire')

    return if @user.badges.include? @hell_fire_badge || @hell_fire_badge.inactive?
    
    if slaved_tool_count_for(@user, tool) > 1500
      process_award @user, @hell_fire_badge
    end
  end
  
  # For players who use more than 250 Lightposts
  def self.award_matchstick_girl
    tool = Tool.cached_single( 'lightposts' )
    @matchstick_girl_badge ||= Badge.caches(:find_by_name, :with => 'Matchstick Girl')

    return if @user.badges.include? @matchstick_girl_badge || @matchstick_girl_badge.inactive?
    
    if slaved_tool_count_for(@user, tool) > 250
      process_award @user, @matchstick_girl_badge
    end
  end
  
  # For players who use more than 500 Lightposts
  def self.award_illuminati
    tool = Tool.cached_single( 'lightposts' )
    @illuminati_badge ||= Badge.caches(:find_by_name, :with => 'Illuminati')

    return if @user.badges.include? @illuminati_badge || @illuminati_badge.inactive?
    
    if slaved_tool_count_for(@user, tool) > 500
      process_award @user, @illuminati_badge
    end
  end
  
  # For players who use more than 1500 Lightposts
  def self.award_keeper_of_the_flame
    tool = Tool.cached_single( 'lightposts' )
    @keeper_of_the_flame_badge ||= Badge.caches(:find_by_name, :with => 'Keeper of the Flame')

    return if @user.badges.include? @keeper_of_the_flame_badge || @keeper_of_the_flame_badge.inactive?
    
    if slaved_tool_count_for(@user, tool) > 1500
      process_award @user, @keeper_of_the_flame_badge
    end
  end
  
  # For players who use more than 250 portals
  def self.award_invisible_man
    tool = Tool.cached_single( 'portals' )
    @invisible_man_badge ||= Badge.caches(:find_by_name, :with => 'Invisible Man')

    return if @user.badges.include? @invisible_man_badge || @invisible_man_badge.inactive?
    
    if slaved_tool_count_for(@user, tool) > 250
      process_award @user, @invisible_man_badge
    end
  end
  
  # For players who use more than 500 portals
  def self.award_telepmogation
    tool = Tool.cached_single( 'portals' )
    @telepmogation_badge ||= Badge.caches(:find_by_name, :with => 'Telepmogation')

    return if @user.badges.include? @telepmogation_badge || @telepmogation_badge.inactive?
    
    if slaved_tool_count_for(@user, tool) > 500
      process_award @user, @telepmogation_badge
    end
  end
  
  # For players who use more than 1500 portals
  def self.award_jaunt
    tool = Tool.cached_single( 'portals' )
    @jaunt_badge ||= Badge.caches(:find_by_name, :with => 'Jaunt')

    return if @user.badges.include? @jaunt_badge || @jaunt_badge.inactive?
    
    if slaved_tool_count_for(@user, tool) > 1500
      process_award @user, @jaunt_badge
    end
  end
  
  # For players who use more than 250 crates
  def self.award_trail_of_splinters
    tool = Tool.cached_single( 'crates' )
    @trail_of_splinters_badge ||= Badge.caches(:find_by_name, :with => 'Trail of Splinters')

    return if @user.badges.include? @trail_of_splinters_badge || @trail_of_splinters_badge.inactive?
    
    if slaved_tool_count_for(@user, tool) > 250
      process_award @user, @trail_of_splinters_badge
    end
  end
  
  # For players who use more than 500 crates
  def self.award_biddy
    tool = Tool.cached_single( 'crates' )
    @biddy_badge ||= Badge.caches(:find_by_name, :with => 'Biddy')

    return if @user.badges.include? @biddy_badge || @biddy_badge.inactive?
    
    if slaved_tool_count_for(@user, tool) > 500
      process_award @user, @biddy_badge
    end
  end
  
  # For players who use more than 1500 crates
  def self.award_the_giver
    tool = Tool.cached_single( 'crates' )
    @the_giver_badge ||= Badge.caches(:find_by_name, :with => 'The Giver')

    return if @user.badges.include? @the_giver_badge || @the_giver_badge.inactive?
    
    if slaved_tool_count_for(@user, tool) > 1500
      process_award @user, @the_giver_badge
    end
  end
  
  # For players who use more than 250 pieces of Armor
  def self.award_shields_up
    tool = Tool.cached_single( 'armor' )
    @shields_up_badge ||= Badge.caches(:find_by_name, :with => 'Shields Up')

    return if @user.badges.include? @shields_up_badge || @shields_up_badge.inactive?
    
    if slaved_tool_count_for(@user, tool) > 250
      process_award @user, @shields_up_badge
    end
  end
  
  # For players who use more than 500 pieces of Armor
  def self.award_beatenest
    tool = Tool.cached_single( 'armor' )
    @beatenest_badge ||= Badge.caches(:find_by_name, :with => 'Beatenest')

    return if @user.badges.include? @beatenest_badge || @beatenest_badge.inactive?
    
    if slaved_tool_count_for(@user, tool) > 500
      process_award @user, @beatenest_badge
    end
  end
  
  # For players who use more than 1500 pieces of Armor
  def self.award_tank
    tool = Tool.cached_single( 'armor' )
    @tank_badge ||= Badge.caches(:find_by_name, :with => 'Tank')

    return if @user.badges.include? @tank_badge || @tank_badge.inactive?
    
    if slaved_tool_count_for(@user, tool) > 1500
      process_award @user, @tank_badge
    end
  end
  
  def self.award_5_missions
    @five_missions_badge ||= Badge.caches(:find_by_name, :with => '5 Missions')

    return if @user.badges.include? @five_missions_badge || @five_missions_badge.inactive?

    missions = Mission.find(:all, :conditions => ['user_id = ?', @user.id])
    if missions.size >= 5
      process_award @user, @five_missions_badge
    end
  end
  
  def self.award_15_missions
    @fifteen_missions_badge ||= Badge.caches( :find_by_name, :with => '15 Missions')

    return if @user.badges.include? @fifteen_missions_badge || @fifteen_missions_badge.inactive?

    missions = Mission.find(:all, :conditions => ['user_id = ?', @user.id])
    if missions.size >= 15
      process_award @user, @fifteen_missions_badge
    end
  end
  
  def self.award_30_missions
    @thirty_missions_badge ||= Badge.caches(:find_by_name, :with => '30 Missions')

    return if @user.badges.include? @thirty_missions_badge || @thirty_missions_badge.inactive?

    missions = Mission.find(:all, :conditions => ['user_id = ?', @user.id])
    if missions.size >= 30
      process_award @user, @thirty_missions_badge
    end
  end

  # For users that invite 5 people that result in actual signups
  def self.award_invites
    @inviting_badge ||= Badge.caches(:find_by_name, :with => 'Inviting')
    @alluring_badge ||= Badge.caches(:find_by_name, :with => 'Alluring')
    @magnetic_badge ||= Badge.caches(:find_by_name, :with => 'Magnetic')

    # Skip if they've got all these badges
    return if @user.badges.include? @inviting_badge and @user.badges.include? @alluring_badge and @user.badges.include? @magnetic_badge
    return if @inviting_badge.inactive? || @alluring_badge.inactive? || @magnetic_badge.inactive?
    
    signup_count = 0
    if @user.beta_keys.any?
      @user.beta_keys.each do |key|
        signups = User.find_by_beta_key_id(key)
        unless signups.nil?
          signup_count += 1
        end
      end
    end

    if signup_count >= 5
      process_award @user, @inviting_badge unless @user.badges.include? @inviting_badge
    end
    
    if signup_count >= 10
      process_award @user, @alluring_badge unless @user.badges.include? @alluring_badge
    end
    
    if signup_count >= 30
      process_award @user, @magnetic_badge unless @user.badges.include? @magnetic_badge
    end
  end

  # TODO- For players who travel a 24 period without setting off any mines.
  def self.award_impervious
    # could do this using event messages, searching for 'just tripped so-and-so's mine'?
  end
  
  # For players who participated in the original version of pmog
  def self.award_alpha_user
    return false # no more...

    @alpha_users = User.find_by_sql("SELECT * 
                                   FROM users
                                   WHERE email IN (SELECT email FROM beta_users WHERE created_on > '2007-09-26 00:00:00' AND created_on < '2007-09-26 23:59:59')")
    @alpha_badge ||= Badge.caches(:find_by_name, :with => 'Alpha')

    return if @alpha_badge.inactive?

    @alpha_users.each do |user|
      next if user.badges.include? @alpha_badge
      process_award user, @alpha_badge
    end
    
  end
  
  # For players who participated in the pre-public release beta (signed up before 05/12/2008)
  def self.award_beta_user
    return false # no more...

    @beta_users = User.find(:all, :conditions => ['created_on <= ?', Time.mktime(2008, 5, 12)])
    @beta_badge ||= Badge.caches(:find_by_name, :with => 'Beta')
    
    return if @beta_users.inactive?
    
    @beta_users.each do |user|
      next if user.badges.include? @beta_badge
      process_award user, @beta_badge
    end
  end
end
