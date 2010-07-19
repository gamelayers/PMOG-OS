require File.dirname(__FILE__) + '/../test_helper'

class GrenadeTest < Test::Unit::TestCase
  fixtures :users, :tools, :grenades, :game_settings
  
  def setup
    super
    @marc = users(:marc)
    @marc.inventory.set(:grenades, 10)
    @suttree = users(:suttree)
    @suttree.inventory.set(:st_nicks, 10)
    @suttree.inventory.set(:grenades, 0)
  end

  def test_create_grenade_success
    assert_difference lambda{@marc.inventory.grenades}, :call, -1 do # take a grenade from marc's inventory
    assert_difference Grenade, :count, 1 do # attach it to suttree
    assert_difference lambda{@marc.user_level.destroyer_cp}, :call, Tool.cached_single(:grenades).classpoints do # give some xp to marc
      @grenade = Grenade.create_and_attach(@marc, {:user_id => @suttree.login})
    end end end

    assert @grenade # this data will get returned to marc
  end

  def test_create_grenade_st_nicked
    StNick.create_and_attach(@suttree, {:user_id => @marc.login})

    assert_difference lambda{@marc.inventory.grenades}, :call, -1 do # take the grenade from marc's inventory
    assert_no_difference Grenade, :count do # fail to attach it to suttree
    assert_difference Event, :count do # send a message to suttree
    assert_raises Grenade::StNicked do # tell marc whats wrong
    assert_difference lambda{@suttree.user_level.vigilante_cp}, :call, Tool.cached_single(:st_nicks).classpoints do # give some xp to suttree
      Grenade.create_and_attach(@marc, {:user_id => @suttree.login})
    end end end end end
  end

  def test_create_grenade_too_many_times
    assert @suttree.grenades.empty? # in case the fixtures get fucked up

    # push it to the limit
    Grenade.create_and_attach(@marc, {:user_id => @suttree.login})
    Grenade.create_and_attach(@marc, {:user_id => @suttree.login})
    Grenade.create_and_attach(@marc, {:user_id => @suttree.login})
    Grenade.create_and_attach(@marc, {:user_id => @suttree.login})
    Grenade.create_and_attach(@marc, {:user_id => @suttree.login})

    # now we should fail
    assert_no_difference Inventory, :count do # don't consume the grenade
    assert_no_difference Grenade, :count do # don't attach the grenade
    assert_raises Grenade::TooManyGrenades do # tell marc whats wrong
      Grenade.create_and_attach(@marc, {:user_id => @suttree.login})
    end end end
  end

  def test_create_grenade_no_inventory
    assert_no_difference lambda{@suttree.inventory.grenades}, :call do # don't consume anything
    assert_no_difference Grenade, :count do # don't attach nonexistant grenades
    assert_raises Grenade::OutOfGrenades do # tell marc whats wrong
      Grenade.create_and_attach(@suttree, {:user_id => @marc.login})
    end end end
  end

  def test_create_grenade_invalid_target
    assert_no_difference Inventory, :count do # give back the grenade
    assert_no_difference Grenade, :count do # don't attach the grenade
    assert_raises User::PlayerNotFound do # tell marc whats wrong
      Grenade.create_and_attach(@marc, {:user_id => "pixley wigglebottom"}) # bogus login
    end end end
  end
end
