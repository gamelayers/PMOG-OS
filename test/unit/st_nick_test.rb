require File.dirname(__FILE__) + '/../test_helper'

class StNickTest < Test::Unit::TestCase
  fixtures :users, :tools, :st_nicks, :game_settings, :ability_statuses
  
  def setup
    super
    @marc = users(:marc)
    @marc.inventory.set(:st_nicks, 10)
    @suttree = users(:suttree)
  end

  def test_invalid_target
    assert_no_difference Inventory, :count do # give back the grenade
    assert_no_difference StNick, :count do # don't attach the grenade
    assert_raises User::PlayerNotFound do # tell marc whats wrong
      StNick.create_and_attach(@marc, {:user_id => "pixley wigglebottom"}) # bogus login
    end end end
  end

  def test_no_st_nick_in_inventory
    @marc.inventory.set(:st_nicks, 0)

    assert_no_difference Inventory, :count do # give back the grenade
    assert_no_difference StNick, :count do # don't attach the grenade
    assert_raises StNick::OutOfStNicksError do # tell marc whats wrong
      StNick.create_and_attach(@marc, {:user_id => @suttree.login})
    end end end
  end

  def test_create_success
    assert_difference lambda{@marc.inventory.st_nicks}, :call, -1 do # take a nick from marc's inventory
    assert_difference StNick, :count, 1 do # attach it to suttree
    assert_difference lambda{@marc.user_level.vigilante_cp}, :call, Tool.cached_single(:st_nicks).classpoints do # give some xp to marc
      StNick.create_and_attach(@marc, {:user_id => @suttree.login})
    end end end
  end

  def test_st_nick_too_many_times
    assert @suttree.st_nicks.empty? # in case the fixtures get fucked up

    # push it to the limit
    StNick.create_and_attach(@marc, {:user_id => @suttree.login})
    StNick.create_and_attach(@marc, {:user_id => @suttree.login})
    StNick.create_and_attach(@marc, {:user_id => @suttree.login})
    StNick.create_and_attach(@marc, {:user_id => @suttree.login})
    StNick.create_and_attach(@marc, {:user_id => @suttree.login})

    # now we should fail
    assert_no_difference Inventory, :count do # don't consume the nick
    assert_no_difference Grenade, :count do # don't attach the nick
    assert_raises StNick::MaximumStNicksError do # tell marc whats wrong
      StNick.create_and_attach(@marc, {:user_id => @suttree.login})
    end end end
  end

  def test_ballistic_nick_under_level
    @marc.user_level.vigilante_cp = 0
    @marc.user_level.save

    assert_no_difference Inventory, :count do # give back the nick
    assert_no_difference StNick, :count do # don't attach the nick
    assert_no_difference BallisticNick, :count do # attach a ballistic nick to suttree
    assert_raises User::InsufficientExperienceError do # tell marc whats wrong
      StNick.create_and_attach(@marc, {:user_id => @suttree.login, :upgrade => {:ballistic => true}})
    end end end end
  end

  def test_ballistic_nick_no_pings
    @marc.available_pings = 0
    @marc.save

    assert_no_difference Inventory, :count do # give back the nick
    assert_no_difference StNick, :count do # don't attach the nick
    assert_no_difference BallisticNick, :count do # attach a ballistic nick to suttree
    assert_raises User::InsufficientPingsError do # tell marc whats wrong
      StNick.create_and_attach(@marc, {:user_id => @suttree.login, :upgrade => {:ballistic => true}})
    end end end end
  end

  def test_ballistic_nick_success
    assert_difference lambda{@marc.available_pings}, :call, -Upgrade.cached_single(:ballistic_nick).ping_cost do # deduct marc's pings
    assert_difference lambda{@marc.inventory.st_nicks}, :call, -1 do # take a nick from marc's inventory
    assert_difference BallisticNick, :count do # attach a ballistic nick to suttree
    assert_no_difference StNick, :count do # but no regular nick
    assert_difference lambda{@marc.user_level.reload.vigilante_cp}, :call, Upgrade.cached_single(:ballistic_nick).classpoints do # give some xp to marc
      StNick.create_and_attach(@marc, {:user_id => @suttree.login, :upgrade => {:ballistic => true}})
    end end end end end
  end

end
