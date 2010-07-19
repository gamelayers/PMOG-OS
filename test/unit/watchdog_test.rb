require File.dirname(__FILE__) + '/../test_helper'

class WatchdogTest < Test::Unit::TestCase
  fixtures :users, :locations, :upgrades, :user_levels, :inventories
  
  def setup
    super
    # marc starts with some mines already
    # he also has a healthy stash of pings
    # and he has lvl20 in all classes
    @marc = users(:marc)
    @location  = locations(:yeah_com)
    @params = { :location_id => @location.id }
  end
  
  def test_no_dog_in_inventory
    @marc.inventory.set :watchdogs, 0

    assert_no_difference Event, :count do
    assert_no_difference Watchdog, :count do
    assert_raises Watchdog::OutOfWatchdogsError do
      Watchdog.create_and_attach(@marc, @params)
    end end end
  end

  def test_underleveled
    @marc.user_level.vigilante_cp = 0
    @marc.user_level.save

    assert_no_difference Event, :count do
    assert_no_difference Watchdog, :count do
    assert_raises User::InsufficientExperienceError do
      Watchdog.create_and_attach(@marc, @params)
    end end end
  end

  def test_bad_url
    @params.merge!(:location_id => 'this is not a location id')

    assert_no_difference Event, :count do
    assert_no_difference Watchdog, :count do
    assert_raises Location::LocationNotFound do
      Watchdog.create_and_attach(@marc, @params)
    end end end
  end

  def test_protected_by_pmog
    @params.merge!(:location_id => Location.find_or_create_by_url('http://thenethernet.com/users/atfriedman').id)

    assert_no_difference Event, :count do
    assert_no_difference Watchdog, :count do
    assert_raises Watchdog::ProtectedByPmog do
      Watchdog.create_and_attach(@marc, @params)
    end end end
  end

  def test_max_dogs_per_player
    GameSetting.value('Max Watchdogs per URL').to_i.times do
      Watchdog.create_and_attach(@marc, @params)
    end

    assert_no_difference Event, :count do
    assert_no_difference Watchdog, :count do
    assert_raises Watchdog::MaximumWatchdogsFromUserError do
      Watchdog.create_and_attach(@marc, @params)
    end end end
  end

  def test_create_success
    assert_difference lambda{@marc.inventory.reload.watchdogs}, :call, -1 do
    assert_difference Event, :count do
    assert_difference Watchdog, :count do
      Watchdog.create_and_attach(@marc, @params)
    end end end
  end
end
