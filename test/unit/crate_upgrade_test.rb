require File.dirname(__FILE__) + '/../test_helper'

class CrateUpgradeTest < Test::Unit::TestCase
  fixtures :upgrades, :users, :locations, :crates, :crate_upgrades, :tools, :levels, :inventories, :ability_statuses

	def setup
		@suttree = users(:suttree)
    @marc = users(:marc)
    @s_crate = crates(:crate_upgrade_test_suttree)
    @m_crate = crates(:crate_upgrade_test_marc)

    @QUESTION = "hurr"
    @ANSWER = "durr"
	end

  def test_loot_exploding_crate
    @marc.datapoints = 10

    @c = crates(:exploding_crate)
    assert @c.crate_upgrade

    # make sure we log the event and send a message if the looting works
    assert_difference(Event, :count, 1) do
      assert loot = @c.loot(@marc, { :answer => @ANSWER })
    end

    # check that we took damage
    assert_equal 0, @marc.datapoints
  end

  def test_loot_exploding_crate_with_armor
    @marc.datapoints = 10
    @marc.inventory.set(:armor, 1)
    @marc.toggle_armor unless @marc.is_armored?

    @c = crates(:exploding_crate)
    assert @c.crate_upgrade

    # make sure we log the event and send a message if the looting works
    assert_difference(Event, :count, 1) do
      assert loot = @c.loot(@marc, { :answer => @ANSWER })
    end

    # check that we took no damage
    assert_equal 10, @marc.datapoints
  end

  def test_loot_locked_crate
    @marc.datapoints = 0
    #@marc.available_pings = Upgrade.cached_single('puzzle_crate').ping_cost

    @c = crates(:puzzle_crate)
    #@c.crate_upgrade = crate_upgrades(:exploding_crate_trap)

    assert @c.crate_upgrade
    @c.inventory.set :datapoints, 1
    @c.crate_upgrade.puzzle_answer = @ANSWER

    # all of these formats should work
    assert @c.crate_upgrade.is_answer?(@ANSWER)
    assert @c.crate_upgrade.is_answer?(@ANSWER.downcase)
    assert @c.crate_upgrade.is_answer?(@ANSWER.titleize)
    assert @c.crate_upgrade.is_answer?(@ANSWER.capitalize)
    assert @c.crate_upgrade.is_answer?("     #{@ANSWER}       ")

    # fail if you don't provide params
    assert_raises(CrateUpgrade::PuzzleCrate_NoAnswer) do
      @c.loot(@marc)
    end

    # fail if the answer is wrong
    params = {:answer => 'wrong answer'}
    assert_raises(CrateUpgrade::PuzzleCrate_WrongAnswer) do
      @c.loot(@marc, params)
    end

    # make sure we log the event and send a message if the looting works
    assert_difference(Event, :count, 1) do
      assert loot = @c.loot(@marc, { :answer => @ANSWER })
      assert_equal 1, loot["datapoints"]
    end

    # check that we got the loot
    assert_equal @marc.datapoints, 1
  end

end
