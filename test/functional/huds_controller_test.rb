require File.dirname(__FILE__) + '/../test_helper'

require 'huds_controller'
# Re-raise errors caught by the controller.
class HudsController; def rescue_action(e) raise e end; end

class HudsControllerTest < Test::Unit::TestCase
  fixtures :users
  
  def setup
    @controller = HudsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new    
  end
  
  def test_requires_login
    get :show, :format => 'ext'
    
    # look for the redirect text.
    assert @response.body =~ /session\/new\?format=ext/
  end
  
  def test_should_accept_ext_extension
    login_as :pmog
    get :show, :format =>'ext'
    assert_response :success
  end
  
  def test_should_create_default_preferences
    @user = User.find_by_login('pmog')
    login_as :pmog
    assert_difference(Preference, :count, 16) do
    # Ensure we add all 16 preferences to the user - we don't do privacy prefs for game events anymore
    assert_difference(@user.preferences, :size, 16) do
      get :show, :format => 'ext'
      @user.preferences(true) #force the reload
      assert_response :success
    end end
  end
  
  def test_should_display_preference_form_in_view
    @user = User.find_by_login('pmog')
    login_as :pmog
    get :show, :format => 'ext'
    
    assert_select "form[action=/users/#{@user.login}/preferences?format=ext] input"
    
    # Find all the various form elements.
    assert @groups = assigns(:groups)
    
    @groups.each do |group|      
      group[:settings].each do |p|
        assert_select "[name='preferences[#{Preference.preferences[p][:text]}]']"
      end
    end
    
    assert_response :success
  end  
end
