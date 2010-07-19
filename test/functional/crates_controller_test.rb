require File.dirname(__FILE__) + '/../test_helper'
require 'crates_controller'
require "#{RAILS_ROOT}/lib/helpers.rb"

# Re-raise errors caught by the controller.
class CratesController; def rescue_action(e) raise e end; end
  
class CratesControllerTest < ActionController::TestCase
  fixtures :users, :tools, :levels, :locations, :upgrades, :inventories, :game_settings, :ability_statuses
  
  def setup
    @controller = CratesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @suttree = users(:suttree)
    @suttree.inventory.set :crates, 10
    @QUESTION = "ping"
    @ANSWER = "pong"
  end
  
  def test_not_site_admin_index_redirect
    login_as :pmog
    get :list
    assert_response 302
    get :index
    assert_redirected_to :controller => 'session', :action => 'new'
    get :search
    assert_redirected_to :controller => 'session', :action => 'new'
  end

# TRUST YOUR UNITS - THIS TEST SHOULDN'T EXIST
#  # Make sure we can't deploy oodles of shit in a crate
#  def test_cannot_overload_crate
#    login_as :suttree
#    @user = User.find(@request.session[:user])
#    @user.reward_datapoints(1001)
#    @location = Location.create(:url => 'http://www.google.co.uk')
#    post :create, {:location_id => @location.id, :crate => { :datapoints => 1001 } }
#    assert :success
#    assert_equal "Maximum of 1000 datapoints allowed", flash[:error]
#  end

  def test_should_loot_crates_from_extension
    login_as :suttree
    @user = User.find(@request.session[:user])
    @user.reward_datapoints 100

    params = {}
    params[:crate] = {}
    params[:crate][:tools] = {}
    params[:crate][:datapoints] = 100

    @location = Location.create(:url => 'http://www.google.co.uk')
    @crate    = Crate.create_and_deposit(@user, @location, params)

    @crate.comments = "Test crate"
    @crate.save
    
    put :loot, { :format => "json", :location_id => @crate.location.id, :id => @crate.id }
    
    # Ensure the window id is properly set.
    # assert @response.body =~ /'window_id', '#{@crate.location.id}/
		assert @response.body =~ /Crate looted/
    
    # Ensure that the link to open the IM window is there.
    #assert @response.body =~ /link_to_im/
    #assert :success
    
    # If you loot it a second time you should see a looted message
    put :loot, { :format => "json", :location_id => @crate.location.id, :id => @crate.id }
    assert @response.body =~ /Sorry, we couldn't find the crate you were looking for.  Perhaps it was already looted?/
  end

 
  def test_should_create_a_puzzle_crate
    login_as :marc
    @user = User.find(@request.session[:user])

    @user.reward_datapoints(999)
    @user.reward_pings(999)
    @location = Location.create(:url => 'http://www.google.co.uk')
    post :create, { :format => "json", 
      :location_id => @location.id,
      :crate => {
        :datapoints => "900",
        :comments => "It's locked",
        :tools => []
      },
      :upgrade => {
        :locked => true,
        :question => "What's the meaning of Life?",
        :answer => '42'
      }
    }

    assert_response 201
    assert c = assigns["crate"]

    assert c.crate_upgrade.puzzle_question
    
    # require 'user' # require this again to get rid of what we did with the module_eval
  end 

  def test_should_create_an_exploding_crate
    login_as :marc
    @user = User.find(@request.session[:user])

    @user.reward_datapoints(999)
    @user.reward_pings(999)
    @user.inventory.set(:mines,1)
    @location = Location.create(:url => 'http://www.google.co.uk')
    post :create, { :format => "json",
      :location_id => @location.id,
      :crate => {
        :comments => "It's trapped",
        :tools => []
      },
      :upgrade => {
        :exploding => true,
      }
    }
    assert_response 201
    assert c = assigns["crate"]

    assert c.crate_upgrade.exploding

    # require 'user' # require this again to get rid of what we did with the module_eval
  end

  def test_dismissable_crates
    # Create two crates, dismiss one and ensure the other one remains
    login_as :suttree
    @user = User.find(@request.session[:user])
    @user.datapoints = 600
    @location = Location.create(:url => 'http://www.google.co.uk')

    params = {}
    params[:crate] = {}
    params[:crate][:tools] = {}

    params[:crate][:datapoints] = 100
    @crate = Crate.create_and_deposit(@user, @location, params)
    @crate.comments = "Test crate"
    @crate.save

    params[:crate][:datapoints] = 500
    @crate2 = Crate.create_and_deposit(@user, @location, params)
    @crate2.comments = "Test crate 2"
    @crate2.save

    # dismiss the crate
    post :dismiss, { :format => "json", :location_id => @crate.location.id, :id => @crate.id }
		assert @response.body =~ /Crate dismissed/

    # ensure crate dismissed
    assert @crate.dismissals.dismissed_by?(@user)
    assert ! @crate2.dismissals.dismissed_by?(@user)
    
    # ensure crate doesn't appear again, and the next one does
    require 'track_controller'
    old_controller = @controller
    @controller = TrackController.new
    @request.env[ 'QUERY_STRING' ] = '&url=' + 'http://www.google.co.uk'
    get :index, { :format => "json", :url => 'http://www.google.co.uk', :version => PMOG_EXTENSION_VERSION  }
    assert :success
    json_response = ActiveSupport::JSON.decode(@response.body)

    assert_nil json_response['crates'][0]['body'] =~ /#{@crate.id}/
    assert json_response['crates'][0]['body'] =~ /#{@crate2.id}/
  end

  protected
  def pickup_crate(url)
    require 'track_controller'
    old_controller = @controller
    @controller = TrackController.new
    @request.env[ 'QUERY_STRING' ] = '&url=' + url
    get :index, { :format => "json", :url => url, :version => PMOG_EXTENSION_VERSION }
    assert :success
    assert @response.body =~ /pmog_single_crate/i
    @controller = old_controller
  end
end
