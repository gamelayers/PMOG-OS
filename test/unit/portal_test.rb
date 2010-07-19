require File.dirname(__FILE__) + '/../test_helper'

# Testing out our Url normalisations
class PortalTest < Test::Unit::TestCase
  fixtures :users, :locations, :portals, :ratings, :misc_actions
  
  def setup
    super

    @suttree = users(:suttree)
    @marc = users(:marc)

    @location = locations(:google_com)
    @params = { 
      :portal => { 
        :title => 'Foo bar', 
        :nsfw => false,
        :destination => 'http://www.google.com'
      },
      :location_id => @location.id,
      :charges => 2, 
      :average_rating => @marc.average_rating
    }
  end
  
  def test_create
    marc = users(:marc)
    existing_portal = portals(:yeah_to_google)
    location        = existing_portal.location
    destination     = existing_portal.destination
    title           = 'Foo bar'
    
    assert_difference Rating, :count do
      assert portal = Portal.new(:location_id => location.id, :destination_id => destination.id, :title => title)
      portal.user = marc
      assert portal.save
      assert_equal portal.location, location
      assert_equal portal.destination, destination
      assert_equal portal.title, title
    end
  end
  
  def test_to_json_overlay
    @portal = portals(:google_to_yeah)
    @result = ActiveSupport::JSON.decode(@portal.to_json_overlay)
    assert_equal @result["id"], @portal.id
    assert_equal @result["average_rating"], @portal.average_rating
    assert_equal @result["nsfw"], @portal.nsfw?
    assert_equal @result["user"], @portal.user.login
    assert_equal @result["destination_url"], @portal.destination.url
  end
  
  def test_should_allow_ratings_using_default_params
    marc = users(:marc)
    portal = portals(:yeah_to_google)
    
    # Rate the portal using default 
    assert_difference Rating, :count do
      assert_equal portal.average_rating, 3
      portal.rate(marc)
      assert_equal portal.average_rating, 3
    end
  end
  
  def test_should_allow_ratings_from_users    
    marc = users(:marc)
    portal = portals(:yeah_to_google)
    
    # Rate the portal
    assert_difference Rating, :count do
      assert_equal portal.average_rating, 3
      portal.rate(marc, 5)
      assert_equal portal.average_rating, 4
    end
    
    # Same user cannot rate the same portal twice.
    assert_no_difference Rating, :count do
      portal.rate(marc, 5)
      assert_equal portal.average_rating, 4
    end
  end
  
  def test_should_normalize_ratings_if_too_low
    marc = users(:marc)
    portal = portals(:yeah_to_google)
    
    # Rate the portal
    assert_difference Rating, :count do
      assert_equal portal.average_rating, 3
      
      # This will give a rating of 0
      portal.rate(marc, -1000)
      assert_equal portal.average_rating, 1
    end
  end
  
  def test_should_normalize_ratings_if_too_high
    marc = users(:marc)
    portal = portals(:yeah_to_google)
    
    # Rate the portal
    assert_difference Rating, :count do
      assert_equal portal.average_rating, 3
      
      # This will give a rating of 5
      portal.rate(marc, 1000)
      assert_equal portal.average_rating, 4
    end
  end
  
  def test_portals_should_transport_users
    user = users(:suttree)
    
    # Fake out the reward mechanism to reduce the dependencies on this test.
    user.instance_eval do
      def tool_uses
         o = OpenStruct.new
         o.instance_eval do
           def reward(sym, options = {})
             true
           end
         end
         o
      end
    end
    portal = portals(:yeah_to_google)
    assert_difference portal.users, :count do 
      assert portal.transport(user)
    end
  end
  
  def test_portal_ratings_can_be_string_or_integer
    user = users(:suttree)
    portal = portals(:yeah_to_google)
    string_rating = "5"
    integer_rating = 4

    assert portal.rate(user, string_rating)
    assert portal.rate(user, integer_rating)
  end
  
  def test_portal_create_and_deposit
    marc = users(:marc)
    existing_portal = portals(:yeah_to_google)
    location        = existing_portal.location
    title           = 'Foo bar'
    params = { 
      :portal => { 
        :title => title, 
        :nsfw => false,
        :destination => 'http://www.google.com'
      },
      :location_id => location.id,
      :charges => 2, 
      :average_rating => marc.average_rating
    }
    assert_no_difference(Portal ,:count) do
      @exception =  assert_raise(Portal::BlankParams) do
        Portal.create_and_deposit(marc, params.except(:portal))
      end
    end

    assert_no_difference(Portal ,:count) do
      @exception =  assert_raise(Portal::BlankHint) do
        Portal.create_and_deposit(marc, params.merge(:portal => params[:portal].merge({ :title => ''})))
      end
    end

    assert_no_difference(Portal ,:count) do
      @exception =  assert_raise(Portal::BlankDestination) do
        Portal.create_and_deposit(marc, params.merge(:portal => params[:portal].merge({ :destination => ''})))
      end
    end

    marc.inventory.set :portals, 0
    assert_no_difference(Portal, :count) do
    assert_raise User::InventoryError do
        Portal.create_and_deposit(marc, params)
    end end

    marc.inventory.deposit :portals
    assert_difference(Portal, :count) do
      @portal = Portal.create_and_deposit(marc, params)
      assert @portal.valid?
    end
  end

  # Testing the switch from habtm to hmt
  def test_portals_users
    @user = User.find :first
    @portal = Portal.find :first
        
    # Make sure this portal has no users and no transportations
    @portal.users = []
    Transportation.destroy_all
    assert_equal [], @portal.users
    assert_equal [], Transportation.find(:all)
  
   
    # Now assign a user and make sure everything lines up
    @portal.users << @user
    assert_equal @portal.users.size, 1
    assert_equal Transportation.find(:first).created_at.to_date, Time.now.utc.to_date
  end

  def test_abundant_no_pings
    @params[:upgrade] = {}
    @params[:upgrade][:give_dp] = true

    # fails if no pings
    @marc.available_pings = 0
    @marc.save

    assert_no_difference Portal, :count do
    assert_raises User::InsufficientPingsError do
      Portal.create_and_deposit(@marc, @params)
    end end
  end

  def test_abundant_underlevel
    @params[:upgrade] = {}
    @params[:upgrade][:give_dp] = true

    @marc.user_level.seer_cp = 0
    @marc.user_level.save

    assert_no_difference Portal, :count do
    assert_raises(User::InsufficientExperienceError) do
      Portal.create_and_deposit(@marc, @params)
    end end
  end

  def test_abundant_success
    @params[:upgrade] = {}
    @params[:upgrade][:give_dp] = true

    assert_difference lambda{@marc.reload.available_pings}, :call, -Upgrade.cached_single('give_dp').ping_cost do
    assert_difference UpgradeUse, :count do
    assert_difference Portal, :count do
      @portal = Portal.create_and_deposit(@marc, @params)
    end end end

    assert @portal
    assert @portal.abundant.to_bool
  end

  def test_abundant_transportation_should_give_you_dp
    portal = portals(:suttrees_abundant_portal)

    assert_difference lambda{@suttree.reload.datapoints}, :call, 2 do
    assert_difference MiscActionUse, :count do
    assert_difference Event, :count do
      portal.transport @marc
    end end end
  end
end
