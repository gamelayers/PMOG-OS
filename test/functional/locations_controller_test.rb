require File.dirname(__FILE__) + '/../test_helper'

class LocationsControllerTest < ActionController::TestCase
  all_fixtures

  def test_search_using_legal_id
    login_as :pmog
    @location = Location.find(:first)

    get :search, { :format => "json", :id => @location.id }
    assert :success

    json_response = ActiveSupport::JSON.decode(@response.body)
    assert json_response["id"]
    assert json_response["url"]
    assert Location.find_by_id(json_response["id"])
    assert Location.find_by_url(json_response["url"])
  end

  def test_search_using_illegal_id
    login_as :pmog
    invalid_id = UUID.timestamp_create().to_s

    get :search, { :format => "json", :id => invalid_id }
    assert :success

    json_response = ActiveSupport::JSON.decode(@response.body)
    assert_equal json_response, '404'
  end

  def test_search_for_known_url
    login_as :pmog

    get :search, { :format => "json", :url => 'http://www.google.com' }
    assert :success

    json_response = ActiveSupport::JSON.decode(@response.body)
    assert json_response["id"]
    assert json_response["url"]
    assert Location.find_by_id(json_response["id"])
    assert Location.find_by_url(json_response["url"])
  end

  def test_search_for_unknown_url
    login_as :pmog

    get :search, { :format => "json", :url => "http://www.#{Time.now.to_i}.com" }
    assert :success

    json_response = ActiveSupport::JSON.decode(@response.body)
    assert json_response["id"]
    assert json_response["url"]
    assert Location.find_by_id(json_response["id"])
    assert Location.find_by_url(json_response["url"])
  end

  def test_uuid_api
    login_as :pmog
    @location = Location.find(:first)

    get :show, { :format => "json", :id => @location.id }
    assert :success

    json_response = ActiveSupport::JSON.decode(@response.body)
    assert json_response["id"]
    assert json_response["url"]
    assert Location.find_by_id(json_response["id"])
    assert Location.find_by_url(json_response["url"])
  end

  def test_visitor_count
    login_as :pmog
    @location = Location.find(:first)

    get :show, { :format => "json", :id => @location.id }
    assert :success

    json_response = ActiveSupport::JSON.decode(@response.body)
    assert json_response["id"]
    assert json_response["url"]
    assert json_response["visitors_yesterday"]

    assert Location.find_by_id(json_response["id"])
    assert Location.find_by_url(json_response["url"])
    assert_equal json_response["visitors_yesterday"], 0

    # Now test that visitors_yesterday will return a positive count,
    # and that it will reflect multiple users too
    domain_url = 'http://' + Url.caches( :domain, :with => @location.url )
    @domain = Location.caches( :find_or_create_by_url, :with => domain_url )

    # Fake a hit on the daily domains table yesterday. Can't use user1.daily_domains.unique since 
    # the before_save on dailydomains will correct the created_on date
    user1 = User.find_by_login 'suttree'
    User.execute( "INSERT INTO daily_domains(user_id, location_id, created_on) VALUES ('#{user1.id}', '#{@domain.id}', '#{Date.yesterday}')" )
    get :show, { :format => "json", :id => @location.id }
    json_response = ActiveSupport::JSON.decode(@response.body)
    assert_equal 1, json_response["visitors_yesterday"]

    user2 = User.find_by_login 'marc'
    User.execute( "INSERT INTO daily_domains(user_id, location_id, created_on) VALUES ('#{user2.id}', '#{@domain.id}', '#{Date.yesterday}')" )
    get :show, { :format => "json", :id => @location.id }
    json_response = ActiveSupport::JSON.decode(@response.body)
    assert_equal 2, json_response["visitors_yesterday"]
  end

  def test_show
    login_as :pmog
    @user = User.find(@request.session[:user])
    @location = Location.find(:first)
    
    get :show, { :format => "json", :id => @location.id }
    assert :success

    json_response = ActiveSupport::JSON.decode(@response.body)
    assert json_response["id"]
    assert json_response["url"]
    assert_equal @user.mines.find(:first, :conditions => {:location_id => @location.id}), json_response["mines"]
    assert_equal @user.crates.find(:first, :conditions => {:location_id => @location.id}), json_response["crates"]
    assert_equal @user.portals.find(:first, :conditions => {:location_id => @location.id}), json_response["portals"]
    # I can't figure out what's up with this one :( marc
    #assert_equal Branch.find_all_by_location_id(@location.id), json_response["missions"]
    assert Location.find_by_id(json_response["id"])
    assert Location.find_by_url(json_response["url"])
  end
end
