require File.dirname(__FILE__) + '/../test_helper'
require 'mines_controller'

# Re-raise errors caught by the controller.
class MinesController; def rescue_action(e) raise e end; end
  
class MinesControllerTest < ActionController::TestCase
  fixtures :users, :levels
  
  def setup
    super   
  end

  def test_cannot_deploy_mines_on_pmog
    login_as :pmog
    current_user = User.find(@request.session[:user])
    current_user.inventory.set( 'mines', 10 )

    [ 'http://pmog.com', 'http://ext.pmog.com', 'http://www.pmog.com', 'http://pmog.com/help', 'http://ext.pmog.com/users' ].each do |url|
      count = Mine.count
      deploy_mine_on(url)
      assert_equal count, Mine.count # mine has not been deployed
      assert @response.body =~ /Ha - we don't think so!/i
    end
  end

  def test_cannot_deploy_mines_on_pmog_profile_pages
    login_as :pmog
    current_user = User.find(@request.session[:user])
    current_user.inventory.set( 'mines', 10 )
    
    [ 'http://pmog.com/users/suttree', 'http://ext.pmog.com/users/justin', 'http://dev.pmog.com/users/pmog' ].each do |url|
      count = Mine.count
      deploy_mine_on(url)
      assert_equal count, Mine.count # mine has not been deployed
      assert @response.body =~ /Ha - we don't think so/i
    end
  end

# there are no minefields =[
#  def test_can_deploy_mines_on_pmog_minefield
#    login_as :pmog
#    current_user = User.find(@request.session[:user])
#    current_user.inventory.set( 'mines', 10 )
#    
#    [ 'http://pmog.com/learn/mines', 'http://ext.pmog.com/learn/mines', 'http://dev.pmog.com/learn/mines' ].each do |url|
#      count = Mine.count
#      deploy_mine_on(url)
#      assert_equal (count + 1), Mine.count # mine has been deployed
#      assert @response.body =~ /you've deployed a test mine! hurrah!/i
#    end
#  end

  def test_not_site_admin_index_redirect
    login_as :pmog
    get :index
    assert_response 302
    get :search
    assert_redirected_to :controller => 'session', :action => 'new'
  end
  
  def deploy_mine_on(url)
    @location = Location.find_or_create_by_url(url)
    require 'mines_controller'
    old_controller = @controller
    @controller = MinesController.new
    get :create, { :format => "js", :location_id => @location.id }
    assert :success
    @controller = old_controller
  end
end
