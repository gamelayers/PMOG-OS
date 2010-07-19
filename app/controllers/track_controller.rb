# The main API for passive tracking in PMOG
class TrackController < ApplicationController
  before_filter :login_required
  before_filter :load_location, :only => [:index, :interesting]
  # before_filter :load_user_preferences, :only => [:construct_openstruct]

  # GET /track.js?url=abc
  # Returns a JSON description of the url and any associated missions, events, users, etc.
  def index
    render :text => '-' and return unless logged_in?
    render :text => '-' and return unless params[:url]
    render :text => '-' and return if params[:url] == 'null'
    render :text => '-' and return if browser_spam

    # Breaking backwards compatability with .420 and below
    render_upgrade_notice and return if params[:version].to_f <= 0.42
    render_upgrade_notice and return if params[:version] == '0.6.2'
    render_upgrade_notice and return if params[:version].delete(".").to_i < 80
    render_upgrade_notice and return if params[:version].delete(".").to_i < 85 && Time.now > Time.parse("August 1, 2009")

    # build the response as an OpenStruct
    struct = construct_openstruct.send(:table)

    UserActivity::update(current_user, params[:version]) if (!current_user.nil? and !params.nil?)

    # here is a really good place to debug this file from
    #puts struct.inspect

    respond_to do |format|
      format.html { render :nothing => true }
      format.xml  { render :nothing => true }
      format.json { render :json => struct.to_json }
      format.js   { render :json => struct.to_json }
    end
  end

  # Setup the location variable, containing all the game elements preset at this location
  def track_location(url)
    return nil unless url
    return nil if url.nil? or url.empty?
    return nil if url == 0 or url == 'http://0' or url == 'null'

    # No eager loading, just hot off the press/memcached action
    Location.caches( :find_or_create_by_url, :with => url )
    # When the url_crc column is in place on the locations table, use this instead
    #Location.caches(:find_or_create_with_hash, :with => url)
  end

  # Reward a user with 2 Datapoints for every unique domain that they browse each day
  # Push this out to BJ?
  def track_domain(url)
    return if @location.nil?

    # Use begin/rescue to catch any errors with Url/URI parsing and continue
    begin
      url = Url.normalise( URI.parse( Url.normalise( url ) ).host )
      domain_url = 'http://' + Url.caches( :domain, :with => url )
      domain = Location.caches( :find_or_create_by_url, :with => domain_url )
      if current_user.daily_domains.unique domain
        # Wearing Armor earns you 2DP per TLD, not wearing armor earns you 3DP per TLD
        dp = (current_user.is_armored? ? GameSetting.value('DP for wearing Armor').to_i : GameSetting.value('DP for not wearing Armor').to_i)
        current_user.reward_datapoints(dp)
      end
    rescue
      nil
    end
  end

  def track_crates
    return nil if @location.user_specific_item(current_user)
    # Crates can be dismissed, so that puzzle crates you can't unlock don't block other crates
    # crate = @location.crates.reject{ |crate| crate.dismissals.dismissed_by? current_user }.first
    crate = @location.crates.first_valid(current_user).first

    return nil if crate.nil?

    Crate.to_hash(:id => crate.id, :type => "crate", :nature => "order", :relationship => current_user.buddies.relationship(crate.user)) do
      render_to_string :text => crate.to_json_overlay()
    end
  end

  def track_giftcards
    return nil if @location.user_specific_item(current_user)
    # Giftcards can be dismissed, so that players don't get stuck on NO BACKSIES!
    #giftcard = @location.giftcards.reject{ |giftcard| giftcard.dismissals.dismissed_by? current_user }.first
    giftcard = @location.giftcards.first_valid(current_user).first

    return nil if giftcard.nil?

    Giftcard.to_hash(:id => giftcard.id, :type => "giftcard", :nature => "order", :relationship => current_user.buddies.relationship(giftcard.user)) do
      render_to_string :text => giftcard.to_json_overlay()
    end
  end

  def track_portals
    # portals are not user specific, so no @location.user_specific_item(current_user)

    # Make sure we only render portals you haven't already taken, or portals
    # they have dismissed, and setup the correct window_id for each tool and overlay
    #portal = @location.portals.reject{ |portal|
    #  portal.users.include? current_user or
    #  portal.dismissals.dismissed_by? current_user or
    #  current_user.preferences.falls_below_quality_threshold(portal) or
    #  current_user.preferences.falls_outside_nsfw_threshold(portal) }.first

    # Is there a portal here you can take?
    # - limit the number of portals examined using your rating and nsfw preferences
    # - reject any subsequent portals that you have dismissed or taken, checking for
    #   dismissals aheads of transportations, as the former is cheaper than the latter
     rating = current_user.preferences.get('The Nethernet Portal Content Quality Threshold').value rescue '3'
     nsfw = current_user.preferences.get('Allow NSFW Content').value.to_bool rescue false
     nsfw ? nsfw_condition = '' : nsfw_condition = 'AND nsfw = 0'

    portals = @location.portals.find( :all, :conditions => "average_rating >= #{rating} #{nsfw_condition}" )
    portals = Portal.find( :all, :conditions => ["average_rating >= ? and branch_id is null and location_id = ? #{nsfw_condition}", rating, @location.id])

    portal = portals.reject{ |p| p.dismissals.dismissed_by? current_user or p.user_ids.include? current_user.id }.first
    #portal = @location.portals.first_valid(current_user, @rating, @nsfw_condition).first

    return nil if portal.nil?

    Portal.to_hash(:id => portal.id, :type => "portal") do
      render_to_string :text => portal.to_json_overlay()
    end
  end

  # destroy the user's armor, or damage them if they don't have any on
  def track_ballistic_nicks
    ballistic_nick = current_user.ballistic_nicks.first
    ballistic_nick_settings = Upgrade.cached_single('ballistic_nick')

    return nil if ballistic_nick.nil?

    overlay_damage = 0
    overlay_style = "nick_bugged" # defined for scope, this value is always redefined below

    ### DISARM ###
    if current_user.disarm_roll?
      disarm_settings = Ability.cached_single(:disarm)
      overlay_style = "nick_disarmed"
      current_user.ability_uses.reward :disarm
      current_user.inventory.deposit :st_nicks
      current_user.deduct_pings disarm_settings.ping_cost

      Event.record :context => 'ballistic_nick_disarmed',
        :user_id => current_user.id,
        :recipient_id => ballistic_nick.perp.id,
        :message => "artfully Disarmed <a href=\"#{host}/users/#{ballistic_nick.perp.login}\">#{ballistic_nick.perp.login}'s</a> Ballistic St Nick!"

    ### DODGE ###
    elsif current_user.dodge_roll?
      dodge_settings = Ability.cached_single(:dodge)
      overlay_style = "nick_dodged"
      current_user.ability_uses.reward :dodge
      current_user.deduct_pings dodge_settings.ping_cost

      Event.record :context => 'ballistic_nick_dodged',
        :user_id => current_user.id,
        :recipient_id => ballistic_nick.perp.id,
        :message => "nimbly Dodged <a href=\"#{host}/users/#{ballistic_nick.perp.login}\">#{ballistic_nick.perp.login}'s</a> Ballistic St Nick!"

    else
      # reward pings for a successful attack
      ballistic_nick.perp.reward_pings Ping.value("Damage Rival") if ballistic_nick.perp.buddies.rivaled_with? current_user

      ### BREAK ARMOR ###
      if current_user.is_armored?
        current_user.destroy_armor
        overlay_style = "nick_armor"

        Event.record :context => 'ballistic_nick_armor',
          :user_id => current_user.id,
          :recipient_id => ballistic_nick.perp.id,
          :message => "had their Armor destroyed by <a href=\"#{host}/users/#{ballistic_nick.perp.login}\">#{ballistic_nick.perp.login}'s</a> Ballistic St Nick!"

      ### DEAL DAMAGE ###
      else
        # we still consume the nick even if the player has no armor, so we do 5 dmg instead
        current_user.deduct_datapoints ballistic_nick_settings.damage
        overlay_damage = ballistic_nick_settings.damage
        overlay_style = "nick_damage"

        Event.record :context => 'ballistic_nick_damage',
          :user_id => current_user.id,
          :recipient_id => ballistic_nick.perp.id,
          :message => "was shocked by <a href=\"#{host}/users/#{ballistic_nick.perp.login}\">#{ballistic_nick.perp.login}'s</a> Ballistic St Nick"
      end
    end

    ballistic_nick_data = Hash[
      :damage => overlay_damage,
      :user => ballistic_nick.perp.login].to_json

    # lastly, destroy the nick (once we're done w/ its relations, namely nick.perp)
    ballistic_nick.destroy

    BallisticNick.to_hash(:id => ballistic_nick.id, :type => overlay_style, :nature => "chaos", :relationship => current_user.buddies.relationship(ballistic_nick.perp)) do
      render_to_string :text => ballistic_nick_data, :layout => false
    end
  end

  # Damage the user if there are any mines on this url, and deplete the mine/armor also
  def track_mines
    mine = @location.mines.first

    return nil if mine.nil?

    # plaintext version of the URL for the events stream
    domain = 'http://' + Url.caches( :domain, :with => @location.url )

    # this all has to out-scope the if/else block coming up
    overlay_style = "mine_bugged" # this never makes it thru
    armor_charges = -1 # this shouldn't make it thru either, if we care about it
    damage = 0

    # Every mine event counts as part of an awsm-attack
    record_attack :user => current_user, :minelayer => mine.user, :location => @location

    # the mine is being set off no matter what happens, so lets deplete it now
    mine.deplete

    mine_settings = Tool.cached_single(:mines)

    # generate the text string for all events starting with the mine itself
    event_mine_text = "Mine on <a href=\"http://#{Url.host(@location.url)}\">#{Url.host(@location.url)}</a>"
    event_mine_text = "Stealth Mine" if mine.stealth
    event_mine_text = "Abundant " + event_mine_text if mine.abundant

    event_data = { :context => 'mine_tripped',
      :user_id => current_user.id,
      :recipient_id => mine.user.id,
      :message => "tripped <a href=\"#{host}/users/#{mine.user.login}\">#{mine.user.login}'s</a> #{event_mine_text}",
      :details => "You left this Mine at <a href=\"#{@location.url}\">#{@location.url}</a> on #{mine.created_at.to_s}."}

    ### DISARM ###
    if current_user.disarm_roll?
      overlay_style = "mine_disarmed"
      current_user.ability_uses.reward :disarm
      current_user.inventory.deposit :mines
      current_user.deduct_pings Ability.cached_single(:disarm).ping_cost

      event_data.merge! :context => 'mine_disarmed',
        :message => "artfully Disarmed <a href=\"#{host}/users/#{mine.user.login}\">#{mine.user.login}'s</a> #{event_mine_text}"

    ### DODGE ###
    elsif current_user.dodge_roll?
      overlay_style = "mine_dodged"
      current_user.ability_uses.reward :dodge
      current_user.deduct_pings Ability.cached_single(:dodge).ping_cost

      event_data.merge! :context => 'mine_dodged',
        :message => "nimbly Dodged <a href=\"#{host}/users/#{mine.user.login}\">#{mine.user.login}'s</a> #{event_mine_text}"

    elsif current_user.is_armored?
      # load vengeance, we have to do math against it
      vengeance_settings = Ability.cached_single(:vengeance)
      # if the player has armor on, all attacks will at least deplete it
      armor_charges = current_user.deplete_armor

      ### VENGEANCE ###
      if (current_user.ability_status.vengeance.to_bool && current_user.levels[:bedouin] >= vengeance_settings.level && current_user.available_pings >= vengeance_settings.ping_cost)
        overlay_style = "mine_vengeance"

        current_user.deduct_pings vengeance_settings.ping_cost
        current_user.ability_uses.reward :vengeance

        # apply the damage to the destroyer
        if mine.abundant
          damage = Upgrade.cached_single(:abundant_mine).damage
        else
          damage = mine_settings.damage
        end
        damage = (damage * vengeance_settings.percentage / 100).to_i
        mine.user.deduct_datapoints damage

        event_data.merge! :context => 'mine_vengeance',
          :message => "took Revenge for <a href=\"#{mine.pmog_host}/users/#{mine.user.login}\">#{mine.user.login}'s</a> #{event_mine_text}",
          :details => "#{event_data[:details]}  -#{damage}DP!"

      else
        current_user.reward_pings Ping.value("Damage Rival") if current_user.buddies.rivaled_with? mine.user

        ### ARMOR BROKEN ###
        if armor_charges == 0
          overlay_style = "mine_armor_destroyed"

          event_data.merge! :context => 'mine_armor_destroyed',
            :message => "broke their Armor on <a href=\"#{current_user.pmog_host}/users/#{mine.user.login}\">#{mine.user.login}'s</a> #{event_mine_text}"

        ### ARMOR DAMAGED ###
        else
          overlay_style = "mine_deflected"

          event_data.merge! :context => 'mine_deflected',
            :message => "foiled <a href=\"#{current_user.pmog_host}/users/#{mine.user.login}\">#{mine.user.login}'s</a> #{event_mine_text} with Armor"
        end
      end
    else
      overlay_style = "mine_damage"
      mine.user.reward_pings Ping.value('Damage Rival') if current_user.buddies.rivaled_with? mine.user

      ### ABUNDANT SUCCESS ###
      if mine.abundant.to_bool
        abundant_mine_settings = Upgrade.cached_single(:abundant_mine)

        unless current_user == mine.user
          current_user.deduct_datapoints abundant_mine_settings.damage
          mine.user.reward_datapoints abundant_mine_settings.damage, false
          damage = abundant_mine_settings.damage
        end

        event_data.merge! :context => 'abundant_mine_tripped'

      ### STANDARD SUCCESS ###
      else
        current_user.deduct_datapoints mine_settings.damage
        damage = mine_settings.damage

        # the default event data is for this event
      end

      ### STEALTH ###
      if mine.stealth
        # this is the highest priority icon
        event_data.merge! :context => 'stealth_mine_tripped'
      end
    end

    Event.record event_data

    # we don't use mine.to_json_overlay because the info we care about is only accessable here
    mine_data = Hash[
         :damage => damage,
         :user => mine.user.login,
         :armor_charges => armor_charges].to_json

    Mine.to_hash(:id => mine.id, :type => overlay_style, :nature => "chaos", :relationship => current_user.buddies.relationship(mine.user)) do
      render_to_string :text => mine_data, :layout => false
    end
  end

  # Damage the user if they have grenades in their queue
  def track_grenades
    grenade = current_user.grenades.first

    return nil if grenade.nil?

    # this all has to out-scope the if/else block coming up
    overlay_style = "grenade_bugged" # this never makes it thru
    armor_charges = -1 # this shouldn't make it thru either, if we care about it
    damage = 0

    grenade.deplete

    grenade_settings = Tool.cached_single(:grenades)

    ### DODGE ###
    if current_user.disarm_roll?
      overlay_style = "grenade_disarmed"
      current_user.ability_uses.reward :disarm
      current_user.inventory.deposit :grenades
      current_user.deduct_pings Ability.cached_single(:disarm).ping_cost

      Event.record :context => 'grenade_disarmed',
        :user_id => current_user.id,
        :recipient_id => grenade.perp.id,
        :message => "plucked <a href=\"#{host}/users/#{grenade.perp.login}\">#{grenade.perp.login}'s</a> Grenade out of the air"

    ### DISARM ###
    elsif current_user.dodge_roll?
      overlay_style = "grenade_dodged"
      current_user.ability_uses.reward :dodge
      current_user.deduct_pings Ability.cached_single(:dodge).ping_cost

      Event.record :context => 'grenade_dodged',
        :user_id => current_user.id,
        :recipient_id => grenade.perp.id,
        :message => "nimbly dodged <a href=\"#{host}/users/#{grenade.perp.login}\">#{grenade.perp.login}'s</a> Grenade"

    elsif current_user.is_armored?
      # load vengeance, we have to do math against it
      vengeance_settings = Ability.cached_single(:vengeance)
      # if the player has armor on, all attacks will deplete it
      armor_charges = current_user.deplete_armor

      ### VENGEANCE ###
      if current_user.ability_status.vengeance.to_bool && current_user.levels[:bedouin] >= vengeance_settings.level && current_user.available_pings >= vengeance_settings.ping_cost
      #if current_user.ability_status.vengeance.to_bool && current_user.levels[:bedouin] >= vengeance_settings.level
        overlay_style = "grenade_vengeance"

        current_user.deduct_pings vengeance_settings.ping_cost
        current_user.ability_uses.reward :vengeance

        # apply the damage to the destroyer
        damage = grenade_settings.damage
        damage = (damage * vengeance_settings.percentage / 100).to_i
        grenade.perp.deduct_datapoints damage

        Event.record :context => 'grenade_vengeance',
          :user_id => current_user.id,
          :recipient_id => grenade.perp.id,
          :message => "took revenge for <a href=\"#{host}/users/#{grenade.perp.login}\">#{grenade.perp.login}'s</a> Grenade"
      else
        ### ARMOR DESTROYED
        if armor_charges == 0
          overlay_style = "grenade_armor_destroyed"

          Event.record :context => 'grenade_armor_destroyed',
            :user_id => current_user.id,
            :recipient_id => grenade.perp.id,
            :message => "smashed their Armor on <a href=\"#{current_user.pmog_host}/users/#{grenade.perp.login}\">#{grenade.perp.login}'s</a> Grenade."

        ### ARMOR DAMAGED ###
        else
          overlay_style = "grenade_deflected"

          Event.record :context => 'grenade_deflected',
            :user_id => current_user.id,
            :recipient_id => grenade.perp.id,
            :message => "foiled <a href=\"#{host}/users/#{grenade.perp.login}\">#{grenade.perp.login}'s</a> Grenade with Armor"
        end
      end
    ### STANDARD SUCCESS ###
    else
      overlay_style = "grenade_damage"

      current_user.deduct_datapoints grenade_settings.damage
      damage = grenade_settings.damage

      grenade.perp.reward_pings Ping.value('Damage Rival') if current_user.buddies.rivaled_with? grenade.perp

      Event.record :context => 'grenade_tripped',
        :user_id => current_user.id,
        :recipient_id => grenade.perp.id,
        :message => "tripped <a href=\"#{host}/users/#{grenade.perp.login}\">#{grenade.perp.login}'s</a> Grenade"
    end

    grenade_data = Hash[
         :user => grenade.perp.login,
         :damage => damage,
         :armor_charges => armor_charges].to_json

    Grenade.to_hash(:id => grenade.id, :type => overlay_style, :nature => "chaos", :relationship => current_user.buddies.relationship(grenade.perp)) do
      render_to_string :text => grenade_data, :layout => false
    end
  end

  # Returns the location and all associated items as an OpenStruct hash, to give us more
  # reliable JSON encoding for use in API calls. I don't like this here, it's too 'fat',
  # but as we're using render_to_string, it doesn't belong in the Location model either
  def construct_openstruct
    return default_location_data if @location.nil?

    # check to see if the user deserves datapoints for this tld
    # track_domain(@location.url)

    # get the response started
    location_data = { :id => @location.id, :url => @location.url }

    # find all events for indepdently displaying items
    ['ballistic_nicks', 'grenades', 'mines', 'giftcards', 'crates', 'portals'].each do |tool|
      tool_data = send("track_#{tool}".to_sym)
      location_data[tool] = Array[tool_data] unless tool_data.nil?
    end

    # FIXME now find the rest of the events that i was unable to fold into the above loop

    # Ask the user to rate the portal, if required
    # Note that we don't check the portal destination url matches the current one, as there
    # are too many redirects out there. Maybe we should just regex to see if the current url
    # is somewhat similar to the portal destination, but we'll worry about that later - duncan 9/01/08
    # Note that you can only rate a portal if you haven't already rated it, or created it.
    # Perhaps, with XUL overlays, we can keep the portal overlay open and ajax up a rating form
    # to do away with the session/cookie store for portal_id's - duncan 13/09/08
    if session[:portal_id] || cookies[:portal_id]
      begin
        @portal = Portal.caches(:find, :with => session[:portal_id])
        if @portal.user.id == current_user.id
          # Charge the portal by one because we don't "charge" portal owners when they take their own portals.
          @portal.increment!(:charges)
          location_data[ :messages ] = []
          location_data[ :messages ] << Portal.to_hash(:type => 'portaltest', :id => @portal.id) do
            render_to_string :text => @portal.to_json_overlay, :layout => false
          end
          location_data[ :messages ].flatten!
        end
        # Only one rating per user
        unless @portal.ratings.collect{ |rating| rating.user == current_user }.any?
          location_data[ :portal_rating ] = []
          location_data[ :portal_rating ] << Portal.to_hash(:type => 'portalrating', :id => @portal.id) do
            render_to_string :text => @portal.to_json_overlay, :layout => false
          end
          location_data[ :portal_rating ].flatten!
        end
      rescue ActiveRecord::RecordNotFound
        # OK to ignore here it just means the session or the cookies had a portal that was not on the current page.
      ensure
        session[:portal_id] = nil
        cookies.delete :portal_id
      end
    end

    # And now for branches, lightposts and missions...
    if session[:mission_id]
      # We're on a mission!
      @mission = Mission.find_with_inactive( :first, :conditions => { :id => session[:mission_id] }, :include => {:branches => :location} )

      # We used find_with_inactive above because a mission author, testing his own mission, will need to see the overlays.
      # Here, we check to see if the mission is inactive and if the current_user is not the mission author. In that event,
      # We don't want them to see anything re: this mission and we'll exit out.
      return default_location_data if @mission.nil? or (! @mission.is_active? and current_user != @mission.user and not site_admin?)

      # Revert to this stricter checking, if missions fail
      #if @mission.branches.collect{ |branch| branch.location.url }.include? @location.url
      #  @branch = @mission.branches.find( :first, :conditions => { :location_id => @location.id } )

      # Do some fuzzy matching of the current url with the mission urls
      begin
        mission_urls = @mission.branches.collect{ |branch| branch.location.url }
      rescue
        mission_urls = []
      end

      variant_url = mission_urls.collect{ |url| Url.caches(:variant_matches, :withs => [url, @location.url, false]) }.select{ |u| u }.first

      if variant_url
        # Note that variant_url will be set to the correct url if the user is there and we
        # don't need to take advantage of fuzzy matching. Also, variant_url should be enough,
        # really, and I'm not clear why I choose to  attempt extracting the url a second time...
        branch_url = Url.caches(:first_match, :withs => [variant_url, mission_urls, false])

        if branch_url
          @branch_location = Location.caches( :find_by_url, :with => branch_url )
          @branch = @mission.branches.find_by_location_id(@branch_location.id)
        else
          @branch = @mission.branches.find_by_location_id(@location.id)
        end

        # Track this stop on the mission, so that we can stop hacking
        session[:mission_locations] << @branch.location_id

        @next = @branch.next
        @previous = @branch.previous

        # Reset location data, if we don't want missions to be interrupted by mines and portals, etc...
        #location_data = { :id => @location.id, :url => @location.url }

        # Render the branch overlay and offer links to the next location
        location_data[ :missions ] = []
        # opts = {}
        # opts[:mission_id] = @mission.id
        # opts[:id] = @branch.id
        # opts[:type] = "branch"
        # opts[:debug_postion] = "Lightpost postion debug: #{@branch.position}" if site_admin?
        # opts[:previous] = white_list(@previous.location.url) unless @previous.nil?
        # opts[:next] = white_list(@next.location.url) unless @next.nil?
        # opts[:name] = format(@mission.name)
        # opts[:avatar] = avatar_path_for_user(:user => @mission.user, :size => 'mini')
        # opts[:url_name] = @mission.url_name
        # opts[:description] = format(@branch.description)
        # opts[:author] = @mission.user.login
        # opts[:testing_mission] = true unless current_user != @mission.user
        #
        # location_data[ :missions ] << opts
        # #location_data[ :missions ].flatten!
        #
        # if current_user == @mission.user && @branch.tested == false
        #   # Assume that if the overlay is rendered, then the branch test is successful
        #   @branch.tested = true
        #   @branch.save
        # end
        location_data[ :missions ] << Branch.to_hash(:type => 'branch', :id => @mission.id) do
          opts = {}
          opts[:total_branches] = @mission.branches.size
          opts[:current_branch] = @branch.position
          opts[:previous] = (@previous.nil?) ? nil : white_list(@previous.location.url)
          opts[:question] = @branch.puzzle.question unless @branch.puzzle.nil?
          opts[:next] = (@next.nil? || !@branch.puzzle.nil?) ? nil : white_list(@next.location.url)
          opts[:branch_id] = @branch.id
          opts[:name] = format(@mission.name)
          opts[:avatar] = avatar_path_for_user(:user => @mission.user, :size => 'mini')
          opts[:url_name] = @mission.url_name
          opts[:description] = format(@branch.description)
          opts[:testing_mission] = current_user == @mission.user,
          opts[:edit_mission_url] = (current_user == @mission.user) ? @mission.url_name : nil

          if current_user == @mission.user && @branch.tested == false
            # Assume that if the overlay is rendered, then the branch test is successful
            @branch.tested = true
            @branch.save
          end

          render_to_string :text => @mission.to_json_overlay(opts), :layout => false
        end
        location_data[ :missions ].flatten!
      else
        location_data[ :missions ] = []
      end
    elsif @location.branches.any?
      # We've found a mission!
      location_data[ :missions ] = []

      # Is there a mission here you can take?
      # - limit the number of mission examined using your rating and nsfw preferences
      # - reject any subsequent portals that you have dismissed or taken, checking for
      #   dismissals aheads of transportations, as the former is cheaper than the latter
      #rating = current_user.preferences.get('The Nethernet Mission Content Quality Threshold').value rescue '3'
      #nsfw = current_user.preferences.get('Allow NSFW Content').value.to_bool rescue false
      #nsfw ? nsfw_condition = '' : nsfw_condition = 'AND missions.nsfw = 0'

      branches = Branch.find_by_sql( ["SELECT branches.*, missions.*
                                       FROM branches, missions
                                       WHERE location_id = ?
                                       AND branches.mission_id = missions.id
                                       AND missions.is_active = 1
                                       AND missions.average_rating >= ?
                                       #{@nsfw_condition}", @location.id, @rating] )

      branch = branches.reject{ |b| b.mission.dismissals.dismissed_by? current_user or b.mission.user_ids.include? current_user.id }.first

      unless branch.nil?
        location_data[ :missions ] << Branch.to_hash(:type => "mission", :id => branch.id) do
          opts = {}
          render_to_string :text => branch.to_json_overlay, :layout => false
        end
        location_data[ :missions ].flatten!
      end
    else
      # See if we can find a mission on a variant of this url
      # Note that this is a cached finder, but it doesn't eager load an
      # additional data, which means the dismissals are always up to date (see just below)
      #@location.branches = Branch.caches(:nearby, :with => @location.url)

      # Variant matches are too slow, let's stop searching for nearby missions
      @location.branches = []

      # We've found a mission, or we're near to one. Bit repetitive, sorry...
      if @location.branches.any?
        location_data[ :missions ] = []

        # Is there a mission here you can take?
        # - limit the number of mission examined using your rating and nsfw preferences
        # - reject any subsequent portals that you have dismissed or taken, checking for
        #   dismissals aheads of transportations, as the former is cheaper than the latter
        # rating = current_user.preferences.get('The Nethernet Mission Content Quality Threshold').value rescue '3'
        # nsfw = current_user.preferences.get('Allow NSFW Content').value.to_bool rescue false
        # nsfw ? nsfw_condition = '' : nsfw_condition = 'AND missions.nsfw = 0'

        branches = Branch.find_by_sql( ["SELECT branches.*, missions.*
                                         FROM branches, missions
                                         WHERE location_id = ?
                                         AND branches.mission_id = missions.id
                                         AND missions.is_active = 1
                                         AND missions.average_rating >= ?
                                         #{@nsfw_condition}", @location.id, @rating] )

        branch = branches.reject{ |b| b.mission.dismissals.dismissed_by? current_user or b.mission.user_ids.include? current_user.id }.first

        unless branch.nil?
          location_data[ :missions ] << Branch.to_hash(:type => "mission", :id => branch.id) do
            opts = {}
            render_to_string :text => branch.to_json_overlay, :layout => false
          end
          location_data[ :missions ].flatten!
        end
      else
        # Just send back an empty array to keep the extension in sync
        location_data[ :missions ] = []
      end
    end

    # And add in the user data and missing fields too
    location_data[:user] = current_user_data(:tracking => true)

    # Add status_effects if they're present
    add_buffs_to(location_data)

    #add_empty_page_objects_to(location_data)
    return OpenStruct.new(location_data)
  end

  # To give us a fighting change against out-of-control browsers, or spammers, this check just boots
  # anyone who hits the tracking page more than n times
  def browser_spam
    max_visits = GameSetting.value('Suspect Limit').to_i
    timestamp = Date.today.to_s
    if session[:pmog_visits] and session[:pmog_visits] > max_visits and session[:pmog_timestamp] == timestamp
      # Too many hits during this time period
      session[:pmog_visits] = session[:pmog_visits].to_i + 1
      Suspect.track( current_user, session[:pmog_visits], session[:pmog_timestamp], request.env[ 'REMOTE_ADDR' ] )
      return true
    elsif session[:pmog_visits] and session[:pmog_timestamp] == timestamp
      # Keep incrementing
      session[:pmog_visits] = session[:pmog_visits].to_i + 1
      return false
    else
      # Either a first visit, or the time period has changed, so start afresh
      session[:pmog_timestamp] = timestamp
      session[:pmog_visits] = 1
      return false
    end
  end

  # We are b0rked, construst a basic hash so that we can at least
  # return something that the browser extension can use
  def default_location_data
    location_data = { :id => nil, :url => params[:url], :user => current_user_data }
    add_empty_page_objects_to(location_data)
    OpenStruct.new(location_data)
  end

  def interesting
    if @location.nil?
      render :nothing => true and return
    end

    # get the response started
    location_data = { :id => @location.id, :url => @location.url, :is_interesting => @location.is_interesting? }

    if not @location.is_interesting?
      # find all events for the user and not the location
      ['ballistic_nicks', 'grenades'].each do |tool|
        tool_data = send("track_#{tool}".to_sym)
        location_data[tool] = Array[tool_data] unless tool_data.nil?
      end
    end

    location_data[:user] = current_user_data(:tracking => true)

    UserActivity::update(current_user, params[:version]) if (!current_user.nil? and !params.nil?)

    render :json => location_data.to_json
  end

  protected
  def load_location
    # figure out the id of this location
    url = Url.extract_and_normalise_from_env(request.env[ 'QUERY_STRING' ], params[:version])
    @location = track_location(url)
  end

  def load_user_preferences
    @rating = current_user.preferences.get('The Nethernet Portal Content Quality Threshold').value rescue '3'
    nsfw = current_user.preferences.get('Allow NSFW Content').value.to_bool rescue false
    nsfw ? @nsfw_condition = '' : nsfw_condition = 'AND nsfw = 0'
  end
end
