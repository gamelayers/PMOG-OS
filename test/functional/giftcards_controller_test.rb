require File.dirname(__FILE__) + '/../test_helper'
require 'giftcards_controller'
require "#{RAILS_ROOT}/lib/helpers.rb"

# Re-raise errors caught by the controller.
class GiftcardsController; def rescue_action(e) raise e end; end
  
class GiftcardsControllerTest < ActionController::TestCase
  fixtures :users, :tools, :levels, :locations, :abilities, :ability_statuses, :inventories
  
  def setup
    super
    # @controller = GiftcardsController.new
    # @request    = ActionController::TestRequest.new
    # @response   = ActionController::TestResponse.new
  end
  
  def test_deploy_giftcard
    login_as :suttree
    @user = User.find(@request.session[:user])
    @user.reward_datapoints(1001)
    @location = Location.create(:url => 'http://www.google.co.uk')
    post :create, { :format => "json", :location_id => @location.id }
    assert_response 201, assigns.inspect
    assert g = assigns["giftcard"]
  end

  def test_loot_giftcard_from_extension
    login_as :suttree
    @user = User.find(@request.session[:user])
    @gc_user = users(:marc)
    @user.update_attributes(:datapoints => 30)
    
    @user.reload
    
    starting_dp = @user.datapoints
    
    @location = Location.find_or_create_by_url(:url => 'http://www.google.co.uk')
    
    # Since we can't loot our own crates, we need to make the crate as someone else.
    @giftcard = Giftcard.create(:location => @location, :user_id => @gc_user.id)
    
    put :loot, { :format => "json", :location_id => @location.id, :id => @giftcard.id }
        
    assert_equal @user.reload.datapoints, starting_dp + Ability.cached_single(:giftcard).value, "Datapoints not awarded to looting user"
    assert_response 200, "http response was not 200"
    
    #If you loot it a second time it should fail
    put :loot, :format => "json", :location_id => @location.id, :id => @giftcard.id
            
    json_response = ActiveSupport::JSON.decode(@response.body)
    assert json_response["flash"]["error"] == "The DP Card you were trying to loot is already gone!"
  end

  def test_loot_giftcard_no_backsies
    login_as :alex # not an admin
    @user = User.find(@request.session[:user])
    @user.update_attributes(:datapoints => 30)
        
    starting_dp = @user.reload.datapoints
    
    @location = Location.find_or_create_by_url(:url => 'http://www.google.co.uk')
    
    # Since we can't loot our own crates, we need to make the crate as someone else.
    @giftcard = Giftcard.create(:location => @location, :user_id => @user.id)
    
    put :loot, { :format => "json", :location_id => @location.id, :id => @giftcard.id }
        
    assert_equal @user.reload.datapoints, starting_dp, "Datapoints awarded to a user who backsied their own giftcard"
    assert_response 401, "http response was not 401"
            
    json_response = ActiveSupport::JSON.decode(@response.body)
    assert json_response["flash"]["error"] == Giftcard::BacksiesError.new.message
  end

  def test_loot_giftcard_creates_awsm
    justin = User.find_by_login('justin')
    suttree = User.find_by_login('suttree')

    login_as :suttree
    @user = User.find(@request.session[:user])

    @location = Location.create(:url => 'http://www.google.co.uk')
    @giftcard = Giftcard.create(:location => @location, :user_id => justin.id)

    num_awsmattacks = Awsmattack.count
    put :loot, { :format => "json", :location_id => @location.id, :id => @giftcard.id }
    assert :success
    assert_equal (num_awsmattacks + 1), Awsmattack.count

    # Make sure that the Awsmattacks are recorded correctly
    suttree_attack = Awsmattack.find(:first, :conditions => {:user_id => suttree.id}, :order => 'created_at DESC')

    assert_equal suttree_attack.context, 'dp_card'
    assert_equal suttree_attack.location_id, @location.id
  end

  def test_dismiss_giftcard
    login_as :suttree
    @user = User.find(@request.session[:user])
    @location = Location.create(:url => 'http://www.google.co.uk')

    @card1 = Giftcard.create(:location => @location, :user_id => @user.id)    
    @card2 = Giftcard.create(:location => @location, :user_id => @user.id)

    post :dismiss, { :format => "json", :location_id => @location.id, :id => @card1.id }
		assert @response.body =~ /dismissed!/

    assert @card1.dismissals.dismissed_by?(@user)
    assert ! @card2.dismissals.dismissed_by?(@user)
    
    require 'track_controller'
    old_controller = @controller
    @controller = TrackController.new
    @request.env[ 'QUERY_STRING' ] = '&url=' + 'http://www.google.co.uk'
    get :index, { :format => "json", :url => 'http://www.google.co.uk', :version => PMOG_EXTENSION_VERSION  }
    assert :success
    json_response = ActiveSupport::JSON.decode(@response.body)

    assert_nil json_response['giftcards'][0]['body'] =~ /#{@card1.id}/ , "Dismissed giftcard found"
    assert json_response['giftcards'][0]['body'] =~ /#{@card2.id}/, "Un-dismissed giftcard not found"
  end
end
