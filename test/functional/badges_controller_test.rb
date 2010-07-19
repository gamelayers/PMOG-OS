require File.dirname(__FILE__) + '/../test_helper'
require 'badges_controller'

# Re-raise errors caught by the controller.
class BadgesController; def rescue_action(e) raise e end; end

class BadgesControllerTest < ActionController::TestCase
  fixtures :users, :badges, :roles, :roles_users, :groups
  
  def setup
    super
  end
  
  def test_badge_index_no_login
    get :index
    assert_redirected_to :controller => 'sessions', :action => "new"
  end
  
  def test_badge_index_with_login_no_user_param
    login_as :pmog
    get :index
    assert_response :success
    assert_select "title", "pmog's badges on The Nethernet"
  end
  
  def test_badge_index_with_login_with_user_param
    login_as :pmog
    get :index, :user_id => "suttree"
    assert_response :success
    assert_select "title", "suttree's badges on The Nethernet"
  end
  
  def test_badge_list_no_login
    get :list
    assert_redirected_to :controller => 'sessions', :action => 'new'
  end
  
  def test_badge_list_with_login_not_admin
    login_as :pmog
    get :list
    assert_redirected_to :controller => 'home'
    assert_equal "You don't have the credentials to view that page", flash[:error]
  end
  
  def test_badge_list_with_login_with_admin
    login_as :marc
    get :list
    assert_response :success
    assert_select "title", "Listing all badges on The Nethernet"
  end
  
  # At this point, we aren't implementing badges/show, so instead of an error,
  # we'll redirect to the badges/index if the user is logged in. If there is no 
  # user session, then the controller will redirect to the login screen
  def test_badge_show_no_login_redirect
    get :show
    assert_redirected_to :controller => 'sessions', :action => 'new'
  end
  
  # Continuing our previous test, if the user is logged in, we'll redirect to the
  # badge index listing and the user should see their own badges.
  def test_badge_show_with_login_redirect
    login_as :pmog
    get :show
    assert_redirected_to :controller => 'badges', :action => 'index'
  end
  
  # At this point, we aren't implementing badges/edit, so instead of an error,
  # we'll redirect to the badges/index if the user is logged in. If there is no 
  # user session, then the controller will redirect to the login screen
  def test_badge_edit_no_login_redirect
    get :edit
    assert_redirected_to :controller => 'sessions', :action => 'new'
  end
  
  # Continuing our previous test, if the user is logged in, we'll redirect to the
  # badge index listing and the user should see their own badges.
  def test_badge_edit_with_login_redirect
    login_as :pmog
    get :edit
    assert_redirected_to :controller => 'badges', :action => 'index'
  end
end
