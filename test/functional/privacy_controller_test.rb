require File.dirname(__FILE__) + '/../test_helper'
require 'privacy_controller'

# Re-raise errors caught by the controller.
class PrivacyController; def rescue_action(e) raise e end; end

class PrivacyControllerTest < ActionController::TestCase
  fixtures :users, :portals, :ratings, :beta_users

  def setup
    super
  end

  def test_delete_history
    @user = User.find_by_login('suttree')
    login_as :suttree

    get :delete_history, :user => {:password_confirmation => 'itsasekrit'}
    assert_redirected_to :action => 'index'

    post :delete_history, :user => {:password_confirmation => 'itsasekrit'}

    assert_equal nil, DailyDomain.find_by_user_id(@user.id)
    assert_redirected_to :action => 'index'
  end

  def test_close_account
    @user = User.find_by_login('justin')
    current_user = @user
    login_as :justin

    # Create a Beta User with this email, so that we can
    # make sure they are deleted later
    BetaUser.create( :email => @user.email )

    # Create a buddy, too
    suttree = Buddy.find_by_login('suttree')
    suttree.add(@user, 'ally')
    #suttree.approve(@user.id, 'ally')
    suttree.add(@user, 'acquaintance')
    #suttree.approve(@user.id, 'acquaintance' )

    get :close_account, :user => {:password_confirmation => 'bad_password_right?'}
    assert_redirected_to :action => 'index'

    get :close_account, :user => {:password_confirmation => 'itsasekrit'}
    assert_redirected_to :action => 'index'

    post :close_account, :user => {:password_confirmation => 'itsasekrit'}

    assert_equal false, @user.has_role?('site_admin')
    assert_equal nil, DailyDomain.find_by_user_id(@user.id)
    assert_equal nil, Topic.find_by_user_id(@user.id)
    assert_equal nil, Post.find_by_user_id(@user.id)
    assert_equal nil, Comment.find_by_user_id(@user.id)
    assert_equal nil, User.find_by_id(@user.id)
    #assert_equal nil, BetaUser.find_by_id(@user.id)
    assert_equal nil, Event.find_by_user_id(@user.id)
    assert_equal nil, Mine.find_by_user_id(@user.id)
    assert_equal nil, Crate.find_by_user_id(@user.id)
    assert_equal nil, Portal.find_by_user_id(@user.id)
    assert_equal nil, StNick.find_by_user_id(@user.id)
    assert_equal nil, Lightpost.find_by_user_id(@user.id)
    assert_equal nil, Mission.find_by_user_id(@user.id)
    assert_equal [], User.find_by_sql("SELECT * FROM buddies_users WHERE buddy_id = '#{@user.id}'")

    assert_redirected_to :action => 'goodbye'
  end
end
