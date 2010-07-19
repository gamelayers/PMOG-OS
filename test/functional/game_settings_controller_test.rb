require File.dirname(__FILE__) + '/../test_helper'

class GameSettingsControllerTest < ActionController::TestCase
  fixtures :game_settings, :users

  def test_can_edit_value
    login_as :suttree
    @user = User.find(@request.session[:user])

    put :update, { :id => 1, :game_setting => {:value => 5} }
    assert_equal '5', GameSetting.find(1).value
  end

  def test_cannot_edit_key
    login_as :suttree
    @user = User.find(@request.session[:user])

    put :update, { :id => 1, :game_setting => {:key => "THIS SHOULD NOT BE EDITABLE"} }
    assert_equal 'DP for wearing Armor', GameSetting.find(1).key
  end
end
