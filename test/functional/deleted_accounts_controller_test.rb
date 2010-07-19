require File.dirname(__FILE__) + '/../test_helper'

class DeletedAccountsControllerTest < ActionController::TestCase
  fixtures :users, :roles, :roles_users
  
  def test_should_get_index
    login_as :marc
    get :index
    assert_response :success
    assert_not_nil assigns(:deleted_accounts)
  end
  
  def test_should_get_redirected
    get :index
    assert_response :redirect
    assert_redirected_to "/"
    assert_equal "You can't access this unless you're an admin!", flash[:notice]
  end
end
