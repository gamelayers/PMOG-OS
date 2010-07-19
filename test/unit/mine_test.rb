require File.dirname(__FILE__) + '/../test_helper'

class MineTest < Test::Unit::TestCase
  fixtures :users, :mines, :locations, :upgrades, :user_levels, :inventories
  
  def setup
    super
    # marc starts with some mines already
    # he also has a healthy stash of pings
    # and he has lvl20 in all classes
    @marc = users(:marc)
    @location  = locations(:yeah_com)
    @params = { :location_id => locations(:yeah_com).id }

    # suttree already has 10 nicks on him
    @suttree = users(:suttree)
  end
  
  def test_create_empty_inventory
    @marc.inventory.set :mines, 0

    assert_no_difference lambda{@marc.inventory.reload.mines}, :call do
    assert_no_difference Mine, :count do
    assert_raises Mine::OutOfMinesError do
      Mine.create_and_deposit(@marc, @params)
    end end end
  end

  def test_create_on_protected_url
    assert_no_difference lambda{@marc.user_level.reload.destroyer_cp}, :call do
    assert_no_difference Event, :count do
    assert_no_difference lambda{@marc.inventory.reload.mines}, :call do
    assert_no_difference Mine, :count do
    assert_raises Location::ProtectedByPmog do
      @deployed_mine, @message = Mine.create_and_deposit(@marc, @params.merge(:location_id => locations(:thenethernet).id))
    end end end end end
  end

  def test_create_success
    assert_difference lambda{@marc.user_level.reload.destroyer_cp}, :call, Tool.cached_single('mines').classpoints do
    assert_difference Event, :count do
    assert_difference lambda{@marc.inventory.reload.mines}, :call, -1 do
    assert_difference Mine, :count do
      @deployed_mine, @message = Mine.create_and_deposit(@marc, @params)
    end end end end

    assert !@deployed_mine.nil?
    assert @message =~ /Mine Laid!/
  end

  def test_create_stealth_no_pings
    @marc.available_pings = 0
    @marc.save

    assert_no_difference lambda{@marc.reload.available_pings}, :call do
    assert_no_difference lambda{@marc.inventory.reload.mines}, :call do
    assert_no_difference Mine, :count do
    assert_raises User::InsufficientPingsError do
      Mine.create_and_deposit @marc, @params.merge!(:stealth => true)
    end end end end
  end

  def test_create_stealth_mine_no_level
    @marc.user_level.destroyer_cp = 0
    @marc.user_level.save

    assert_no_difference lambda{@marc.reload.available_pings}, :call do
    assert_no_difference lambda{@marc.inventory.reload.mines}, :call do
    assert_no_difference Mine, :count do
    assert_raises User::InsufficientExperienceError do
      Mine.create_and_deposit @marc, @params.merge!(:stealth => true)
    end end end end
  end

  def test_create_stealth_mine_success
    assert_difference lambda{@marc.user_level.reload.destroyer_cp}, :call, Upgrade.cached_single('stealth_mine').classpoints do
    assert_no_difference Event, :count do
    assert_difference lambda{@marc.reload.available_pings}, :call, -Upgrade.cached_single('stealth_mine').ping_cost do
    assert_difference lambda{@marc.inventory.reload.mines}, :call, -1 do
    assert_difference Mine, :count, 1 do
      @new_mine, text = Mine.create_and_deposit @marc, @params.merge!(:stealth => true)
    end end end end end

    assert @new_mine.stealth
  end

  def test_create_abundant_mine_no_pings
    @marc.available_pings = 0
    @marc.save

    assert_no_difference lambda{@marc.reload.available_pings}, :call do
    assert_no_difference lambda{@marc.inventory.reload.mines}, :call do
    assert_no_difference Mine, :count do
    assert_raises User::InsufficientPingsError do
      Mine.create_and_deposit @marc, @params.merge!(:abundant => true)
    end end end end
  end

  def test_create_abundant_mine_no_level
    @marc.user_level.destroyer_cp = 0
    @marc.user_level.save

    assert_no_difference lambda{@marc.reload.available_pings}, :call do
    assert_no_difference lambda{@marc.inventory.reload.mines}, :call do
    assert_no_difference Mine, :count do
    assert_raises User::InsufficientExperienceError do
      Mine.create_and_deposit @marc, @params.merge!(:abundant => true)
    end end end end
  end

  def test_create_abundant_mine_success
    assert_difference lambda{@marc.user_level.reload.destroyer_cp}, :call, Upgrade.cached_single('abundant_mine').classpoints do
    assert_difference lambda{@marc.reload.available_pings}, :call, -Upgrade.cached_single('abundant_mine').ping_cost do
    assert_difference lambda{@marc.inventory.reload.mines}, :call, -1 do
    assert_difference Mine, :count, 1 do
      @new_mine, @minefield = Mine.create_and_deposit @marc, @params.merge!(:abundant => true)
    end end end end

    assert @new_mine.abundant
  end

  def test_create_abundant_stealth_no_pings
    # this test assumes that stealth mines don't have a ping cost of zero
    @marc.available_pings = Upgrade.cached_single('abundant_mine').ping_cost
    @marc.save

    assert_no_difference lambda{@marc.reload.available_pings}, :call do
    assert_no_difference lambda{@marc.inventory.reload.mines}, :call do
    assert_no_difference Mine, :count do
    assert_raises User::InsufficientPingsError do
      Mine.create_and_deposit @marc, @params.merge!(:abundant => true, :stealth => true)
    end end end end
  end

  def test_create_abundant_stealth_success
    assert_difference lambda{@marc.user_level.reload.destroyer_cp}, :call, Upgrade.cached_single('stealth_mine').classpoints + Upgrade.cached_single('abundant_mine').classpoints do
    assert_no_difference Event, :count do
    assert_difference lambda{@marc.reload.available_pings}, :call, -(Upgrade.cached_single('stealth_mine').ping_cost + Upgrade.cached_single('abundant_mine').ping_cost) do
    assert_difference lambda{@marc.inventory.reload.mines}, :call, -1 do
    assert_difference Mine, :count, 1 do
      @new_mine, text = Mine.create_and_deposit @marc, @params.merge!(:abundant => true, :stealth => true)
    end end end end end

    assert @new_mine.stealth
    assert @new_mine.abundant
  end

  def test_create_blocked_by_st_nick
    5.times do
      StNick.create_and_attach(@suttree, { :user_id => @marc.login })
    end
    
    5.times do |x|
      assert_raises Mine::StNickedError do
        @deployed_mine, @text = Mine.create_and_deposit(@marc, @params)
      end
      assert @deployed_mine.nil?
    end
    
    # All St.Nicks are cleared.
    @deployed_mine, @text = Mine.create_and_deposit(@marc, @params)
    assert !@deployed_mine.nil?
  end

  def test_create_dodge_st_nick
    @dodge = Ability.find_by_url_name('dodge')
    @dodge.percentage = 100
    @dodge.save
    StNick.create_and_attach(@suttree, { :user_id => @marc.login })

    assert_difference lambda{@marc.user_level.reload.bedouin_cp}, :call, @dodge.classpoints do
    assert_difference lambda{@marc.user_level.reload.destroyer_cp}, :call, Tool.cached_single('mines').classpoints do
    assert_difference lambda{@marc.reload.available_pings}, :call, -@dodge.ping_cost do
    assert_difference lambda{@marc.inventory.reload.mines}, :call, -1 do
    assert_difference Mine, :count do
    assert_difference AbilityUse, :count do
    assert_difference ToolUse, :count do
      @new_mine, @minefield = Mine.create_and_deposit @marc, @params
    end end end end end end end
  end

  def test_create_disarm_st_nick
    @disarm = Ability.find_by_url_name('dodge')
    @disarm.percentage = 100
    @disarm.save
    StNick.create_and_attach(@suttree, { :user_id => @marc.login })

    assert_difference lambda{@marc.user_level.reload.bedouin_cp}, :call, @disarm.classpoints do
    assert_difference lambda{@marc.user_level.reload.destroyer_cp}, :call, Tool.cached_single('mines').classpoints do
    assert_difference lambda{@marc.reload.available_pings}, :call, -@disarm.ping_cost do
    assert_difference lambda{@marc.inventory.reload.mines}, :call, -1 do
    assert_difference Mine, :count do
    assert_difference AbilityUse, :count do
    assert_difference ToolUse, :count do
      @new_mine, @minefield = Mine.create_and_deposit @marc, @params
    end end end end end end end
  end

end
