require File.dirname(__FILE__) + '/../test_helper'

class WatchdogsControllerTest < ActionController::TestCase
  fixtures :users, :watchdogs, :levels, :game_settings
  
  def test_max_watchdogs_from_user
    # Setup a url with 2 Watchdogs attached
    login_as :marc
    @user = User.find(@request.session[:user])
    @user.inventory.set('watchdogs', 10)
    @location = Location.find(:first)
    max_dogs = GameSetting.value('Max Watchdogs per URL').to_i

    # Attach 2 watchdogs
    (max_dogs - 1).times do
      @location.watchdogs.create( :user => @user )
    end

    # Confirm that we can attach 1 more Watchdog
    assert_difference lambda{@location.reload.watchdogs.size}, :call do
      put :attach, :location_id => @location.id, :format => "json"
    end
    
    # Confirm that we cannot attach another Watchdog
    num_watchdogs = @location.reload.watchdogs.size
    put :attach, :location_id => @location.id, :format => "json"
    assert_equal num_watchdogs, @location.watchdogs.reload.size
  end

  def test_max_watchdogs_from_other_user
    @marc = User.find_by_login('suttree')
    @location = Location.find(:first)

    # Attach 5 watchdogs
    5.times do
      @location.watchdogs.create( :user => @marc )
    end
    assert_equal 5, @location.reload.watchdogs.size
    num_watchdogs = @location.reload.watchdogs.size

    # However, another user may still put a Watchdog on this url
    login_as :marc
    @user = User.find(@request.session[:user])
    @user.inventory.set('watchdogs', 10)

    put :attach, :location_id => @location.id, :format => "json"
    assert_equal (num_watchdogs + 1), @location.watchdogs.reload.size
  end
end
