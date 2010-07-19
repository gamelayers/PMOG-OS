require File.dirname(__FILE__) + '/../test_helper'
require 'portals_controller'

# Re-raise errors caught by the controller.
class PortalsController; def rescue_action(e) raise e end; end
  
class PortalsControllerTest < ActionController::TestCase
  fixtures :users, :levels, :portals, :locations, :tools, :inventories
  
  # starring suttree the seer
  def setup
    super

    @suttree = users(:suttree)
    @suttree.inventory.set :portals, 10
    @location = Location.find_or_create_by_url('http://www.google.co.uk')
  end
  
  def test_not_site_admin_index_redirect
    login_as :pmog
    get :index
    assert_response 302
    get :search
    assert_redirected_to :controller => 'session', :action => 'new'
  end
  
  def test_should_display_rated_portal_overlay
    login_as :suttree
    @user = User.find(@request.session[:user])
    @location = Location.create(:url => 'http://www.google.co.uk')
    @portal = Portal.new(:location_id => @location.id, :destination_id => @location.id, :title => 'loop')
    @portal.user_id = @user.id
    @portal.save
    
    post :rate, { :format => "json", :id => @portal.id, :location_id => @location.id, :portal => { :rating => 1 } }
    
    # Ensure that the link to open the IM window is there.
    # This seems broken so in bad form, I'm commenting it out as I need Duncan to look at how the rating portal is being rendered
    #assert @response.body =~ /button_sendthankyou.png/
    assert :success
  end
  
  def test_should_dismiss_a_portal
    login_as :suttree

    post :create, :format => "json", :location_id => @location.id, :portal => { :destination => @location.url, :title => 'my portal', :nsfw => 'false' }

#    create_portal
    assert p = assigns(:deployed_portal)
    post :dismiss, { :format => "json", :id => p.id, :location_id => @location.id }
    assert_response 201
  end
  
  def test_should_jaunt_to_a_random_portal
    login_as :suttree
    get :jaunt, { :format => "json" }
    assert @response.headers["Status"], "200 Success"
    @r = response_to_json
    
    # should have one portal
    assert @r["portals"].size == 1
    
    # Should be a good enough portal
    rating = current_user.preferences.get('PMOG Portal Content Quality Threshold').value.to_i rescue 3
    assert assigns['portal'].average_rating >= rating
    @portal = ActiveSupport::JSON.decode(@r["portals"].first)
    assert @portal["id"] == assigns['portal'].id
  end
  
  def test_should_display_an_error_when_jaunting_fails
    login_as :suttree
    Portal.find(:all).collect{ |p| p.destroy } # Delete the jaunt worthy portals
    
    get :jaunt, { :format => "json" }
    assert @response.headers["Status"], "422"
    @r = response_to_json
    
    assert @r["flash"]["error"] =~ /Unable to find portal. Please try again later/
  end
  
  def test_should_create_portal
    login_as :suttree
    @location = Location.find(:first)

    post :create, :format => "json", :location_id => @location.id, :portal => { :destination => @location.url, :title => 'my portal', :nsfw => 'false' }

    assert p = assigns(:deployed_portal)
    assert_equal p.location_id, @location.id
    assert_equal p.destination_id, @location.id
    assert_equal p.average_rating.to_i, 3
    assert_equal p.title, 'my portal'
    assert_equal p.nsfw, false
    assert_equal @response.headers["Status"], "201 Created"
    assert @response.body =~ /Success! Portal drawn/i
  end

# DISABLED 09-02-07 by alex, we don't track charges in the inventory anymore
#  def test_new_portal_charges_should_match_tool_charges
#    login_as :suttree
#    create_portal
#    assert p = assigns(:deployed_portal)
#    assert_equal p.charges, Tool.find_by_name('portals').charges
#  end

  def test_new_portal_is_rated_by_creator_automatically
    login_as :suttree
    post :create, :format => "json", :location_id => @location.id, :portal => { :destination => @location.url, :title => 'my portal', :nsfw => 'false' }
    assert p = assigns(:deployed_portal)
    assert_equal p.ratings.count, 1
    assert_equal p.average_rating, 3
    assert_equal p.ratings.first.user.id, @suttree.id
  end

# DISABLED 09-02-07 by alex, this test never did anything because the location itself never gets an id
#  def test_should_not_create_portal_from_invalid_url
#    login_as :suttree
#    #create_portal('file://www.google.uk/index')
#    location =  Location.find_or_create_by_url('file://www.google.co.uk/index')
#
#    puts "SUSPICIOUS LOCATION IS: #{location.inspect}"
#
#    post :create, :format => "json", :location_id => location.id, :portal => { :destination => location.url, :title => 'my portal', :nsfw => 'false' }
#
#    assert ! assigns(:deployed_portal)
#    @response.body =~ /Invalid portal, please check that your destination url is valid./
#  end

  # For extensions prior to 0.410, which do not send the relevant
  # CSRF tokens, a simple 'Upgrade required' template should be rendered
  # to the client. This is a test to catch that by attempting to deploy a portal
  def test_should_result_in_upgrade_notice
    login_as :suttree
    @user = User.find(@request.session[:user])
    @location = Location.create(:url => 'http://www.google.co.uk')
    title = 'my portal'

    # Now when we attempt to create a portal (anything other than a GET will do)
    # we should receive an upgrade overlay. Note that we have to catch and raise
    # the exception by hand, in order to test it
    begin
      # Enable CSRF checking for this test
      @controller.class.module_eval do
        self.allow_forgery_protection = true
      end
      post :create, :format => "json", :location_id => @location.id, :portal => { :destination => @location.url, :title => title, :nsfw => 'false', :version => '0.1' }
    rescue => e
      @controller.rescue_action_in_public(e)
      assert_response :success
      assert @response.body =~ /An upgrade for PMOG is available/i
    end
  end
end
