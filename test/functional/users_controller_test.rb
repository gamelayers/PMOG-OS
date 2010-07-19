require File.dirname(__FILE__) + '/../test_helper'
require 'users_controller'


# Re-raise errors caught by the controller.
class UsersController; def rescue_action(e) raise e end; end

class UsersControllerTest < Test::Unit::TestCase
  include ApplicationHelper
  fixtures :users, :user_levels, :levels, :portals, :missions, :locations, :crates, :mines, :inventories, :brain_busters

  def setup
    @controller = UsersController.new
    @request    = ActionController::TestRequest.new
    @request.env[ 'HTTP_HOST' ] = 'thenethernet.com'
    @response   = ActionController::TestResponse.new
    # This user is initially valid, but we may change its attributes.
    @valid_user = users(:pmog)

    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true

    @emails = ActionMailer::Base.deliveries
    @emails.clear
  end

  def test_navigation_not_logged_in
    get :index

    # The top links
    assert_tag "a", :content => /OpenID/, :attributes => { :href => "/openid/new" }
    assert_tag "a", :content => /Sign up/, :attributes => { :href => "/users/new" }

    # The big section links
    assert_tag "a", :content => /Explore/,    :attributes => { :href => "/events" }
    assert_tag "a", :content => /Forums/,   :attributes => { :href => "/posts/latest" }
    assert_tag "a", :content => /Missions/, :attributes => { :href => "/missions" }
    assert_tag "a", :content => /Guide/, :attributes => { :href => "/guide" }

    # This shouldn't show up because it'show for only logged in folks.
    assert_no_tag "a", :content => /You/
  end

  def test_navigation_logged_in
    login = 'marc'

    login_as login.to_sym
    get :index

    # The upper user navigation menu
    # First the link to the logged in users profile
    assert_tag "a", :content => /#{login}/, :attributes => { :href => "/users/#{login}" }

    #FIXME then the rest of the top nav, once that is more stable (i'm looking at you, invite friends)

    # Then the link to logout
    assert_tag "a", :content => /Sign Out/, :attributes => { :href => "/session" }

    # Now the large section links
    assert_tag "a", :content => /You/, :attributes => { :href => "/users/#{login}" }
    assert_tag "a", :content => /Explore/,    :attributes => { :href => "/events" }
    assert_tag "a", :content => /Forums/,   :attributes => { :href => "/posts/latest" }
    assert_tag "a", :content => /Missions/, :attributes => { :href => "/missions" }
    assert_tag "a", :content => /Guide/, :attributes => { :href => "/guide" }
  end

  def test_show_bad_params
    login_as :suttree
    get :show, :id => 'bad_id'
    assert flash[:error] == "Player Not Found", "Error was '#{flash[:error]}' instead of 'Player Not Found'"
    assert_redirected_to(home_url)
  end

  def test_show_using_json
    login_as :suttree
    get :show, :id => users(:marc).login, :format => 'json'
    json_response = ActiveSupport::JSON.decode(@response.body)

    # Make sure that the response doesn't contain any of the keys we want to protect
    assert (json_response.keys - User::private_api_fields) == json_response.keys
    assert_response :success
  end

  def test_create
    # Invited by marc
    marc = users(:marc)

    beta_key = BetaKey.create(:user_id => marc.id)
    assert beta_key.valid?

    # Stash the beta key into the cookies
    @request.cookies['beta_key'] = CGI::Cookie.new('beta_key', beta_key.key)

    @request.env[ 'HTTP_HOST' ] = 'test.pmog.com'

    # A new user should have been given a set of items and and 1 crate created by PMOG on their profile
    assert_difference Inventory, :count, 2 do

      get :new

      # An event should be created that the user signed up.
      # An event should be created that the user accepted an invite request.
      assert_difference Event, :count, 2 do
        post :create , :user => { :login => 'eerttus', :password => '1qaz2wsx', :password_confirmation => '1qaz2wsx', :email => 'eerttus@suttree.com', "date_of_birth(1i)" => '1975', "date_of_birth(2i)" => '2', "date_of_birth(3i)" => '23' }, :captcha_id => 13, :captcha_answer => "hill"
      end
    end
    assert u = assigns(:user)

    # The beta key should have been assigned to the new user.
    assert u.beta_key = beta_key

    assert_equal u.user_level.primary_class, 'shoat'

    # the user should automatically get a cookie assigned to remember them.
    assert_equal u.remember_token, cookies['auth_token'].first

    assert flash[:notice] =~ /You have successfully signed up for PMOG!/i
    assert_redirected_to('/')
  end


# underage b& don't get banned no more =/
#  # Must be over 13
#  def test_create_underage
#    assert_no_difference User, :count do
#      get :new
#      post :create , :user => { :login => 'eerttus', :password => '1qaz2wsx', :password_confirmation => '1qaz2wsx', :email => 'eerttus@suttree.com', "date_of_birth(1i)" => Date.today.year.to_s, "date_of_birth(2i)" => Date.today.month.to_s, "date_of_birth(3i)" => Date.today.day.to_s }
#    end
#
#    u = assigns(:user)
#    assert_template 'create_fail'
#
#    assert_equal assigns(:user).errors.on(:date_of_birth), "Sorry, You must be over 13 years old to play PMOG."
#  end

  def test_create_overage
    assert_difference User, :count do
      get :new
      post :create , :user => { :login => 'eerttus', :password => '1qaz2wsx', :password_confirmation => '1qaz2wsx', :email => 'eerttus@suttree.com', "date_of_birth(1i)" => '1975', "date_of_birth(2i)" => '2', "date_of_birth(3i)" => '23' }, :captcha_id => 13, :captcha_answer => "hill"
    end

    assert_no_difference User, :count do
      date = 13.years.ago
      post :create , :user => { :login => 'eerttus', :password => '1qaz2wsx', :password_confirmation => '1qaz2wsx', :email => 'eerttus@suttree.com', "date_of_birth(1i)" => date.year.to_s, "date_of_birth(2i)" => date.month.to_s, "date_of_birth(3i)" => date.day.to_s }, :captcha_id => 13, :captcha_answer => "hill"
    end

    assert_no_difference User, :count do
      date = 12.years.ago
      post :create , :user => { :login => 'eerttus', :password => '1qaz2wsx', :password_confirmation => '1qaz2wsx', :email => 'eerttus@suttree.com', "date_of_birth(1i)" => date.year.to_s, "date_of_birth(2i)" => date.month.to_s, "date_of_birth(3i)" => date.day.to_s }, :captcha_id => 13, :captcha_answer => "hill"
    end
  end

  def test_create_bad_params
    @request.env[ 'HTTP_HOST' ] = 'test.pmog.com'

    # Note that we have to pass in some kind of dob otherwise the model whinges in its validators :(
    params = { "date_of_birth(1i)" => '1975', "date_of_birth(2i)" => '2', "date_of_birth(3i)" => '23'}
    # :login => 'eerttus', :password => '1qaz2wsx', :password_confirmation => '1qaz2wsx', :email => 'eerttus@suttree.com', "date_of_birth(1i)" => '1975', "date_of_birth(2i)" => '2', "date_of_birth(3i)" => '23' }

    # Missing All Required Params
    assert_no_difference User, :count do
      get :new
      post :create , :user => params
    end
    u = assigns(:user)
    assert_template 'create_fail'

    ["can't be blank", "is too short (minimum is 3 characters)"].each do |err|
      assert u.errors.on(:email).include?(err)
    end

    ["can't be blank", "is too short (minimum is 3 characters)"].each do |err|
      assert u.errors.on(:login).include?(err)
    end

    ["can't be blank", "is too short (minimum is 4 characters)"].each do |err|
      assert u.errors.on(:password).include?(err)
    end

    assert_equal u.errors.on(:password_confirmation), "can't be blank"

    # Params are too short or invalid
    params.merge!({ :email => 'a', :login => 'b', :password => 'c', :password_confirmation => 'd' })

    assert_no_difference User, :count do
      post :create , :user => params
    end

    ["is too short (minimum is 3 characters)", "is invalid"].each do |err|
      assert assigns(:user).errors.on(:email).include?(err)
    end

    # FIXME: The length is being validated twice.
    ["is too short (minimum is 3 characters)", "is too short (minimum is 3 characters)"].each do |err|
      assert assigns(:user).errors.on(:login).include?(err)
    end

    ["is too short (minimum is 4 characters)", "doesn't match confirmation"].each do |err|
      assert assigns(:user).errors.on(:password).include?(err)
    end

    # Invalid Formats
    params.merge!({ :email => 'invalid email', :login => 'invalid login', :password => 'invalid password', :password_confirmation => 'invalid password' })

    assert_no_difference User, :count do
      post :create , :user => params
    end

    assert_equal assigns(:user).errors.on(:login), 'can contain only numbers and letters.'
    assert_equal assigns(:user).errors.on(:email), 'is invalid'
  end

  def test_json_is_secure
    login_as :marc
    get :show, :id => 'suttree', :format => 'json'

    assert :success
    json_response = ActiveSupport::JSON.decode(@response.body)
    assert json_response.include?('login')
    assert json_response.include?('total_datapoints')

    assert ! json_response.include?('salt')
    assert ! json_response.include?('email')
    assert ! json_response.include?('password')
    assert ! json_response.include?('remember_token')
    assert ! json_response.include?('crypted_password')
    assert ! json_response.include?('remember_token_expires_at')
  end

  def test_json_includes_full_level_information
    login_as :suttree
    get :show, :id => 'suttree', :format => 'json'

    assert :success
    json_response = ActiveSupport::JSON.decode(@response.body)

    assert json_response.include?('levels')
    assert json_response['levels'].include?('benefactor')
    assert json_response['levels'].include?('destroyer')
    assert json_response['levels'].include?('pathmaker')
    assert json_response['levels'].include?('vigilante')
    assert json_response['levels'].include?('bedouin')
    assert json_response['levels'].include?('seer')
  end

  protected
  def rand_will_return(action_type)
    @controller.instance_eval do
      @@action_type = action_type
      def random_action(num)
        @@action_type
      end
    end
  end
end
