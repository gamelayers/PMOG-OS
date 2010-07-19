require File.dirname(__FILE__) + '/../test_helper'
require 'track_controller'

# Re-raise errors caught by the controller.
class TrackController; def rescue_action(e) raise e end; end
  
class TrackControllerTest < ActionController::TestCase
  fixtures :users, :tools, :locations, :missions, :branches, :portals, :messages, :inventories, :ability_statuses
  
  def setup
    super   
    @marc = users(:marc)
    @suttree = users(:suttree)
    @justin = users(:justin)
    @location = Location.find_or_create_by_url('http://www.suttree.com')
    @request.env[ 'QUERY_STRING' ] = @location.url
  end

  def test_ballistic_nick_naked
    login_as :suttree
    @suttree.toggle_armor if @suttree.is_armored?

    StNick.create_and_attach(@marc, {:user_id => @suttree.login, :upgrade => {:ballistic => true}})

    assert_difference lambda{@suttree.reload.datapoints}, :call, -Upgrade.cached_single(:ballistic_nick).damage + GameSetting.value('DP for not wearing Armor').to_i do
      get :index, { :format => "json", :url => @location.url, :version => PMOG_EXTENSION_VERSION }
    end
  end

  def test_ballistic_nick_armored
    login_as :suttree

    @suttree.ability_status.armor_charges = 3
    @suttree.ability_status.armor_equipped = true
    @suttree.ability_status.save

    StNick.create_and_attach(@marc, {:user_id => @suttree.login, :upgrade => {:ballistic => true}})

    assert_difference lambda{ @suttree.reload.datapoints}, :call, GameSetting.value('DP for wearing Armor').to_i do
    assert_difference Event, :count do
      get :index, { :format => "json", :url => @location.url, :version => PMOG_EXTENSION_VERSION }
    end end

    assert_equal @suttree.ability_status.reload.armor_charges, 0
    assert_equal @suttree.ability_status.reload.armor_equipped, false
  end

  def test_ballistic_nick_dodge
    login_as :marc

    @user = User.find(@request.session[:user])
    @user.ability_status.dodge = 1
    @user.ability_status.disarm = 0
    @user.ability_status.save

    # set dodge % from 0 to 100 so it will go off here (and only go off here)
    @dodge = Ability.find_by_url_name('dodge')
    @dodge.percentage = 100
    @dodge.save
    @disarm = Ability.find_by_url_name('disarm')
    @disarm.percentage = 0
    @disarm.save

    url = 'http://www.foo.com'

    StNick.create_and_attach(@marc, {:user_id => @marc.login, :upgrade => {:ballistic => true}})

    get :index, { :format => "json", :url => url, :version => PMOG_EXTENSION_VERSION }

    json_response = ActiveSupport::JSON.decode(@response.body)
    json_response["ballistic_nicks"][0]["body"] =~ /nick_dodge/

    assert :success
  end

  def test_ballistic_nick_disarm
  end

  def test_track_grenade_on_defenseless_player
    login_as :suttree

    @suttree.toggle_armor if @suttree.is_armored?

    Grenade.create_and_attach(@marc, {:user_id => @suttree.login})

    assert_difference lambda{@suttree.reload.datapoints}, :call, - Tool.cached_single(:grenades).damage + GameSetting.value('DP for not wearing Armor').to_i do
    assert_difference Event, :count do
      get :index, { :format => "json", :url => @location.url, :version => PMOG_EXTENSION_VERSION }
    end end

    assert :success
  end

  def test_track_grenade_on_armored_player
    login_as :suttree
    @suttree.toggle_armor unless @suttree.is_armored?

    Grenade.create_and_attach(@marc, {:user_id => @suttree.login})

    starting_charges = @suttree.ability_status.armor_charges

    assert_difference lambda{@suttree.ability_status.armor_charges}, :call, -1 do
    assert_difference lambda{@suttree.reload.datapoints}, :call, GameSetting.value('DP for wearing Armor').to_i do
    assert_difference Event, :count do
      get :index, { :format => "json", :url => @location.url, :version => PMOG_EXTENSION_VERSION }
    end end end

    assert :success
  end

  def test_mine_vengeance_no_pings
    # prep a mine, and set marc's abilities
    Mine.create( :user_id => @suttree.id, :location_id => @location.id )

    @marc.ability_status.vengeance = true
    @marc.ability_status.armor_equipped = true
    @marc.ability_status.armor_charges = 3
    @marc.ability_status.save

    @marc.available_pings = 0
    @marc.save

    login_as :marc

    assert_difference lambda{@marc.ability_status.reload.armor_charges}, :call, -1 do
    assert_difference lambda{@marc.reload.datapoints}, :call, GameSetting.value('DP for wearing Armor').to_i do
    assert_no_difference lambda{@suttree.reload.datapoints}, :call do
      get :index, { :format => "json", :url => @location.url, :version => PMOG_EXTENSION_VERSION }
    end end end
    
    assert :success
  end

  def test_mine_vengeance_no_level
    # prep a mine, and set marc's abilities
    Mine.create( :user_id => @marc.id, :location_id => @location.id )

    @suttree.ability_status.vengeance = true
    @suttree.ability_status.armor_equipped = true
    @suttree.ability_status.armor_charges = 3
    @suttree.ability_status.save

    login_as :suttree

    assert_difference lambda{@suttree.ability_status.reload.armor_charges}, :call, -1 do
    assert_difference lambda{@suttree.reload.datapoints}, :call, GameSetting.value('DP for wearing Armor').to_i do
    assert_no_difference lambda{@marc.reload.datapoints}, :call do
      get :index, { :format => "json", :url => @location.url, :version => PMOG_EXTENSION_VERSION }
    end end end
    
    assert :success
  end

  def test_mine_no_vengeance_settings
    # prep a mine, and set marc's abilities
    Mine.create( :user_id => @suttree.id, :location_id => @location.id )

    @marc.ability_status.vengeance = false
    @marc.ability_status.armor_equipped = true
    @marc.ability_status.armor_charges = 3
    @marc.ability_status.save

    login_as :marc

    assert_difference lambda{@marc.ability_status.reload.armor_charges}, :call, -1 do
    assert_difference lambda{@marc.reload.datapoints}, :call, GameSetting.value('DP for wearing Armor').to_i do
    assert_no_difference lambda{@suttree.reload.datapoints}, :call do
      get :index, { :format => "json", :url => @location.url, :version => PMOG_EXTENSION_VERSION }
    end end end
    
    assert :success
  end

  def test_mine_vengeance_success
    # prep a mine, and set marc's abilities
    Mine.create( :user_id => @suttree.id, :location_id => @location.id )
    @location.mines.reload

    @marc.ability_status.vengeance = true
    @marc.ability_status.armor_equipped = true
    @marc.ability_status.armor_charges = 3
    @marc.ability_status.save

    @suttree.ability_status.armor_equipped = false
    @suttree.ability_status.save

    login_as :marc

    assert_difference lambda{@marc.reload.available_pings}, :call, -Ability.cached_single(:vengeance).ping_cost do # vengeance costs marc pings
    assert_difference lambda{@marc.ability_status.reload.armor_charges}, :call, -1 do # he still loses an armor charge
    assert_difference lambda{@marc.reload.datapoints}, :call, GameSetting.value('DP for wearing Armor').to_i do # he gets dp for browsing a url
    assert_difference lambda{@suttree.reload.datapoints}, :call, -(Tool.cached_single(:mines).damage * Ability.cached_single(:vengeance).percentage / 100) do # duncan loses the damage that his mine would have done
      get :index, { :format => "json", :url => @location.url, :version => PMOG_EXTENSION_VERSION }
    end end end end
    
    #assert :success
  end

  # marc defends vs suttree's grenade
  def test_grenade_vengeance_no_pings
    Grenade.create_and_attach(@suttree, {:user_id => @marc.login})

    @marc.ability_status.vengeance = true
    @marc.ability_status.armor_equipped = true
    @marc.ability_status.armor_charges = 3
    @marc.ability_status.save

    @marc.available_pings = 0
    @marc.save

    login_as :marc

    assert_difference lambda{@marc.ability_status.reload.armor_charges}, :call, -1 do
    assert_difference lambda{@marc.reload.datapoints}, :call, GameSetting.value('DP for wearing Armor').to_i do
    assert_no_difference lambda{@suttree.reload.datapoints}, :call do
      get :index, { :format => "json", :url => @location.url, :version => PMOG_EXTENSION_VERSION }
    end end end
    
    assert :success
  end

  # suttree defends vs marc's grenade
  def test_grenade_vengeance_no_level
    Grenade.create_and_attach(@marc, {:user_id => @suttree.login})

    @suttree.ability_status.vengeance = true
    @suttree.ability_status.armor_equipped = true
    @suttree.ability_status.armor_charges = 3
    @suttree.ability_status.save

    login_as :suttree

    assert_difference lambda{@suttree.ability_status.reload.armor_charges}, :call, -1 do
    assert_difference lambda{@suttree.reload.datapoints}, :call, GameSetting.value('DP for wearing Armor').to_i do
    assert_no_difference lambda{@marc.reload.datapoints}, :call do
      get :index, { :format => "json", :url => @location.url, :version => PMOG_EXTENSION_VERSION }
    end end end
    
    assert :success
  end

  # marc defends vs suttree's grenade
  def test_grenade_no_vengeance_settings
    Grenade.create_and_attach(@suttree, {:user_id => @marc.login})

    @marc.ability_status.vengeance = false
    @marc.ability_status.armor_equipped = true
    @marc.ability_status.armor_charges = 3
    @marc.ability_status.save

    login_as :marc

    assert_difference lambda{@marc.ability_status.reload.armor_charges}, :call, -1 do
    assert_difference lambda{@marc.reload.datapoints}, :call, GameSetting.value('DP for wearing Armor').to_i do
    assert_no_difference lambda{@suttree.reload.datapoints}, :call do
      get :index, { :format => "json", :url => @location.url, :version => PMOG_EXTENSION_VERSION }
    end end end
    
    assert :success
  end

  # marc defends vs suttree's grenade
  def test_grenade_vengeance_success
    Grenade.create_and_attach(@suttree, {:user_id => @marc.login})

    @marc.ability_status.vengeance = true
    @marc.ability_status.armor_equipped = true
    @marc.ability_status.armor_charges = 3
    @marc.ability_status.save

    @suttree.ability_status.armor_equipped = false
    @suttree.ability_status.save

    login_as :marc

    assert_difference lambda{@marc.reload.available_pings}, :call, -Ability.cached_single(:vengeance).ping_cost do
    assert_difference lambda{@marc.ability_status.reload.armor_charges}, :call, -1 do
    assert_difference lambda{@marc.reload.datapoints}, :call, GameSetting.value('DP for wearing Armor').to_i do
    assert_difference lambda{@suttree.reload.datapoints}, :call, -(Tool.cached_single(:grenades).damage * Ability.cached_single(:vengeance).percentage / 100) do
      get :index, { :format => "json", :url => @location.url, :version => PMOG_EXTENSION_VERSION }
    end end end end
    
    assert :success
  end
  
  def test_tripping_mine_creates_attack
    # Create a mine so that we can trip it
    Mine.create( :user_id => @justin.id, :location_id => @location.id )

    # Now trip the mines and check the Awsmattacks are created
    login_as :suttree
    num_awsmattacks = Awsmattack.count
    get :index, { :format => "json", :url => @location.url, :version => PMOG_EXTENSION_VERSION }
    assert :success
    assert_equal (num_awsmattacks + 1), Awsmattack.count

    # Make sure that the Awsmattack is recorded correctly
    suttree_attack = Awsmattack.find(:first, :conditions => {:user_id => @suttree.id}, :order => 'created_at DESC')
    assert_equal suttree_attack.context, 'mine'
    assert_equal suttree_attack.creator.login, @justin.login
    assert_equal suttree_attack.location_id, @location.id
  end

  def test_should_trip_mines_from_extension    
    login_as :suttree
    
    # Take off armor first (this is gonna hurt)
    @suttree.toggle_armor if @suttree.is_armored?
    
    url = 'http://www.foo.com'
    plant_mine_on(url)

    assert_difference Event, :count do
      get :index, { :format => "json", :url => url, :version => PMOG_EXTENSION_VERSION }
    end    

    # Ensure the post effect is added to shake the window
    json_response = ActiveSupport::JSON.decode(@response.body)
    json_response["mines"][0]["body"] =~ /mine_damage/
    
#    # We should send a tauntable message to person who planted the mine.
#    assert m = assigns["message"]
#    assert_equal m.context, "taunt"
#    assert_equal m.deferred_recipient.id, @suttree.id
    assert :success
  end

  def test_should_dodge_if_disarm_is_off
    login_as :marc
    @user = User.find(@request.session[:user])
    @user.ability_status.dodge = 1
    @user.ability_status.disarm = 0
    @user.ability_status.save

    # set dodge % from 0 to 100 so it will go off here (and only go off here)
    @dodge = Ability.find_by_url_name('dodge')
    @dodge.percentage = 100
    @dodge.save
    @disarm = Ability.find_by_url_name('disarm')
    @disarm.percentage = 0
    @disarm.save

    url = 'http://www.foo.com'
    plant_mine_on(url)

    get :index, { :format => "json", :url => url, :version => PMOG_EXTENSION_VERSION }

    json_response = ActiveSupport::JSON.decode(@response.body)
    json_response["mines"][0]["body"] =~ /mine_dodge/

    assert :success
  end

  def test_should_disarm_first_if_available
    login_as :marc
    @user = User.find(@request.session[:user])
    @user.ability_status.dodge = 1
    @user.ability_status.disarm = 1
    @user.ability_status.save

    # set dodge % from 0 to 100 so it will go off here (and only go off here)
    @dodge = Ability.find_by_url_name('dodge')
    @dodge.percentage = 100
    @dodge.save
    @disarm = Ability.find_by_url_name('disarm')
    @disarm.percentage = 100
    @disarm.save

    url = 'http://www.foo.com'
    plant_mine_on(url)

    get :index, { :format => "json", :url => url, :version => PMOG_EXTENSION_VERSION }

    json_response = ActiveSupport::JSON.decode(@response.body)
    json_response["mines"][0]["body"] =~ /mine_disarm/

    assert :success
  end

  
  def test_should_not_shake_window_when_wearing_armor
    login_as :suttree
    add_tools(@suttree)
    @suttree.toggle_armor unless @suttree.is_armored?
    
    url = 'http://www.foo.com'
    plant_mine_on(url)

    get :index, { :format => "json", :url => url, :version => PMOG_EXTENSION_VERSION }
    
    #FIXME mines don't give a failure i don't think, this should be more stringent

    assert :success
  end

  ## Users can only mine themselves on the minefield
  #def test_should_trip_your_mines_on_pmog_minefield
    #marc = User.find_by_login('marc')
    #suttree = User.find_by_login('suttree')
    #@location = Location.find_or_create_by_url('http://pmog.com/learn/mines')
    #@request.env[ 'QUERY_STRING' ] = @location.url

    ## Deploy a mine on the minefields as pmog and suttree
    #Mine.create( :user_id => marc.id, :location_id => @location.id )
    #Mine.create( :user_id => suttree.id, :location_id => @location.id )

    ## Now trip the mines and make sure we trip the right ones
    #login_as :suttree

    ## We have to set QUERY_STRING so that the tracker works correctly
    #get :index, { :format => "json", :url => @location.url, :version => PMOG_EXTENSION_VERSION }
    #assert :success

    ## Should trip our own mine
    #json_response = ActiveSupport::JSON.decode(@response.body)

    #assert_equal 1, json_response['mines'].size
    #json_response['mines'].first['type'] == "minefield"

    ## Should not trip justin's mine
##    @request.env[ 'QUERY_STRING' ] = @location.url
    #get :index, { :format => "json", :url => @location.url, :version => PMOG_EXTENSION_VERSION }
    #assert :success

    #json_response = ActiveSupport::JSON.decode(@response.body)

    #assert_nil json_response['mines']
  #end

  ## Just to be sure, introduce a new user and make sure
  ## that they don't trigger any mines
  #def test_should_not_trip_other_mines_on_pmog_minefield
    #pmog = users(:pmog)
    #marc = users(:marc)
    #@location = Location.find_or_create_by_url('http://pmog.com/learn/mines')
    #@request.env[ 'QUERY_STRING' ] = @location.url

    ## Deploy a mine on the minefields as pmog only
    #Mine.create( :user_id => pmog.id, :location_id => @location.id )

    ## Now log in as a user who has not interacted with the minefield
    ## and make sure they don't trip any mines at all
    #login_as :marc

    ## We have to set QUERY_STRING so that the tracker works correctly
    #get :index, { :format => "json", :url => @location.url }
    #assert :success

    ## Should not trip any mines
##    @request.env[ 'QUERY_STRING' ] = @location.url
    #get :index, { :format => "json", :url => @location.url }
    #assert :success

    #json_response = ActiveSupport::JSON.decode(@response.body)
    #assert_equal 0, json_response['mines'].size
  #end
  
  def test_never_show_mission_found_overlay_for_drafts
    # Login as k41d3n as he's also the mission author. 
    # The mission found overlay should never appear for 
    # drafts that haven't been published.
    login_as :k41d3n
    
    # Get a mission from the fixtures generated by k41d3n
    mission = missions(:mission_with_long_text)
    # Sanity check the mission
    assert mission.is_active?

    # Get the location of the first branch of the mission,
    location = mission.branches.first.location
  
    force_track_location(location)
        
    # We verify this by asserting the mission's first branch is returned.
    assert @response.body =~ /#{mission.id}/
    
    # Now, we deactivate the mission, we'll assume that by going
    # back to the location of a non-published mission, we won't see the
    # mission found overlay. Even if we're the author.
    mission.deactivate!
    
    # Sanity check the inactive-ness
    assert !mission.is_active?
    
    # Go back to the same url we got the mission found overlay on
    get :index, { :format => "json", :url => location.url, :version => PMOG_EXTENSION_VERSION }
    
    # Assert that we don't get the overlay for the mission found
    assert_nil @response.body =~ /#{mission.branches.first.id}/
  end
  
  def test_parse_portals_and_missions_that_are_outside_of_content_threshold
    # Login as k41d3n as he's also the mission author. 
    user = users(:suttree)
    user.preferences.toggle( Preference.preferences[:minimum_mission_rating][:text], 5 )
    login_as :suttree
    
    # Get a mission from the fixtures generated by k41d3n
    mission = missions(:mission_with_long_text)
    mission.update_attribute(:average_rating, 3)
    # Sanity check the mission
    assert mission.is_active?

    #Get the location of the first branch of the mission,
    location = mission.branches.first.location
  
    force_track_location(location)
    
    # We verify this by asserting the take a mission button is not present because it falls below
    # the content quality threshold.
    assert_nil @response.body =~ /button_takemission.png/
    
    # The portal should be found however even though because it checks a different content threshold.
    assert !response_to_json["portals"].empty?
  end
  
  def test_should_display_a_portal_tested_overlay_for_portal_authors
    login_as :suttree
    @user = User.find(@request.session[:user])
    @location = Location.create(:url => 'http://www.google.co.uk')
    @portal = Portal.new(:location_id => @location.id, :destination_id => @location.id, :title => 'loop')
    @portal.user_id = @user.id
    @portal.save
    @request.session[:portal_id] = @portal.id 
    @request.cookies[:portal_id] = @portal.id
    
    charges = @portal.charges
    force_track_location(@location)
    json = response_to_json
    assert json.keys.include?('portals')
    assert ActiveSupport::JSON.decode(json['portals'][0]['body'])['title'] == 'loop'
    assert_response :success
    
    # Ensure the portal owner is not charged for taking their own portal.
    assert @portal.reload.charges == charges+1
  end

  # Tools planted on profile pages are only for their owners
  def test_should_find_only_your_items_on_profile_pages
    login_as :suttree
    @user = User.find(@request.session[:user])

    # Plant a mine as pmog on suttree's page
    url = 'http://pmog.com/users/suttree'
    plant_mine_on(url)

    # Check that PMOG can't trip it
    get :index, { :format => "json", :url => url, :version => PMOG_EXTENSION_VERSION }
    assert :success
    assert_equal nil, @response.body =~ /images\/ext\/mines\/button_sendmessage.png/i

    # And now check that suttree *can* trip it
    login_as :suttree
    @user = User.find(@request.session[:user])

    url = 'http://pmog.com/users/pmog'
    get :index, { :format => "json", :url => url }
    assert :success

    # Ensure that the link to open the IM window is there.
    assert_equal nil, @response.body =~ /images\/ext\/mines\/button_sendmessage.png/i
  end
  
  def test_tracking_versions_before_and_after_0416
    login_as :suttree
    @user = User.find(@request.session[:user])

    url = 'http://www.suttree.com'
    [ "0.416", "0.417" ].each do |version|
      get :index, { :format => "json", :url => url, :version => version }
      assert :success
    end
  end
  
  def test_wearing_armor_earns_two_dp_per_tld
    login_as :suttree
    @user = User.find(@request.session[:user])

    # This should earn me 2 DP
    @user.inventory.set :armor, 1
    @user.toggle_armor unless @user.is_armored?

    current_dp = @user.datapoints

    @location = Location.find_or_create_by_url('http://www.suttree.com')
    force_track_location(@location)

    assert_equal (current_dp + GameSetting.value('DP for wearing Armor').to_i), @user.reload.datapoints

    # This should earn me nothing
    @location = Location.find_or_create_by_url('http://www.suttree.com/about')
    force_track_location(@location)
    assert_equal (current_dp + GameSetting.value('DP for wearing Armor').to_i), @user.reload.datapoints
  end

  def test_wearing_no_armor_earns_three_dp_per_tld
    login_as :suttree
    @user = User.find(@request.session[:user])

    # This should earn me 3 DP
    @user.toggle_armor if @suttree.is_armored?

    current_dp = @user.datapoints
    @location = Location.find_or_create_by_url('http://www.suttree.com')
    force_track_location(@location)
    assert_equal (current_dp + GameSetting.value('DP for not wearing Armor').to_i), @user.reload.datapoints

    # This should earn me nothing
    @location = Location.find_or_create_by_url('http://www.suttree.com/about')
    force_track_location(@location)
    assert_equal (current_dp + GameSetting.value('DP for not wearing Armor').to_i), @user.reload.datapoints
  end

  protected
  def force_track_location(location, version = PMOG_EXTENSION_VERSION)
    # Hackery duped from test_helper.rb to force the controller to track our URL
    @controller.class.class_eval { @@sekret_url = location.url }
    @controller.instance_eval do
      def track_location(url)
        @location = Location.find_by_url(@@sekret_url)
        @location
      end
    end
    @request.env[ 'QUERY_STRING' ] = "version=#{version}&url=#{location.url}"
    get :index, { :format => "json", :url => location.url, :version => version }
  end
end
