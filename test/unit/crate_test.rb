require File.dirname(__FILE__) + '/../test_helper'

class CrateTest < Test::Unit::TestCase
  fixtures :upgrades, :users, :user_levels, :tools, :locations, :crates, :tools, :levels, :inventories, :ability_statuses

	def setup
		@suttree = users(:suttree)
    # suttree has 0 pings
    # suttree has 10 crates and 10 mines
    # suttree has lvl 5 all classes

    @marc = users(:marc)
    # marc has 1000 pings
    # marc has 10 crates and 10 mines
    # marc has lvl 20 all classes
    
    @location = Location.find(:first)

    # basic stub to help us get started
    @params = {}
    @params[:crate] = {}
    @params[:crate][:datapoints] = 0
    @params[:crate][:tools] = {}
    @params[:crate][:tools][:mines] = 0

    @QUESTION = "hurp"
    @ANSWER = "durp"
	end

  ##########################
  # TEST CREATE AND DEPOSIT
  #
  def test_no_params
    crate = nil
    assert_no_difference(Crate, :count) do
    assert_raises(Crate::InvalidParameters) do
			 crate = Crate.create_and_deposit(@suttree, @location, {})
		end end
    assert_equal nil, crate
  end

  def test_no_crate
    @suttree.inventory.set( :crates, 0 )

    assert_no_difference Crate, :count do
    assert_raises(Crate::NoCrateToDeposit) do
			 Crate.create_and_deposit(@suttree, @location, @params)
		end end
  end
   
  def test_create_empty_crate 
    assert_no_difference Crate, :count do
    assert_raises(Crate::EmptyCrateError) do
			 Crate.create_and_deposit(@suttree, @location, @params)
		end end
  end

  def test_no_shoats_allowed
    @params[:crate][:datapoints] = 10
    @suttree.user_level.benefactor_cp = 0
    @suttree.user_level.save

    assert_no_difference Crate, :count do
    assert_raises(User::InsufficientExperienceError) do
			Crate.create_and_deposit(@suttree, @location, @params)
		end end
  end

  def test_negative_dp
    @params[:crate][:datapoints] = -1
    @params[:crate][:tools][:mines] = 5
		crate = nil
    assert_no_difference Crate, :count do
    assert_raises(Crate::InvalidCrateInventory_NegativeDatapoints) do
			 crate = Crate.create_and_deposit(@suttree, @location, @params)
		end end
    assert_equal nil, crate
  end

  def test_insufficient_dp
    @params[:crate][:datapoints] = @suttree.datapoints + 100
		crate = nil
    assert_no_difference Crate, :count do
    assert_raises(User::InsufficientDPError) do
			 crate = Crate.create_and_deposit(@suttree, @location, @params)
		end end
    assert_equal nil, crate
  end

  def test_too_much_loot
    @suttree.datapoints = 10001
    @suttree.save
    @params[:crate][:datapoints] = 10000

    assert_no_difference Crate, :count do
    assert_raises(Crate::InvalidCrateInventory_TooManyDatapoints) do
			 Crate.create_and_deposit(@suttree, @location, @params)
		end end
  end

  def test_not_enough_loot
    @params[:crate][:datapoints] = 2

    assert_no_difference Crate, :count do
    assert_raises(Crate::InvalidCrateInventory_NotEnoughLoot) do
			 Crate.create_and_deposit(@suttree, @location, @params)
		end end
  end

  def test_valid_crate
    # works, user has dp and crates
    @suttree.datapoints = 500
    @suttree.save
    @suttree.inventory.set( :mines, 5 )
    @params[:crate][:datapoints] = 500
    @params[:crate][:tools][:mines] = 5

    crate = nil
    assert_difference lambda{@suttree.inventory.reload.mines}, :call, -5 do
    assert_difference lambda{@suttree.reload.datapoints}, :call, -@params[:crate][:datapoints] do
    assert_difference Crate, :count do
      crate = Crate.create_and_deposit(@suttree, @location, @params)
    end end end

    assert crate
  end

  ###########
  # UPGRADES
  # 
  def test_upgrade_not_specified
    @params[:upgrade] = {}

    assert_no_difference Crate, :count do
    assert_raises(CrateUpgrade::NoUpgradeSpecified) do
      Crate.create_and_deposit(@suttree, @location, @params)
    end end
  end

  # EXPLODING CRATES
  def test_exploding_crate_no_pings
    @params[:upgrade] = {}
    @params[:upgrade][:exploding] = true
    @suttree.inventory.set :mines, 1

    assert_no_difference Crate, :count do
    assert_raises(User::InsufficientPingsError) do
       Crate.create_and_deposit(@suttree, @location, @params)
    end end
  end

  def test_exploding_crate_no_mine
    @params[:upgrade] = {}
    @params[:upgrade][:exploding] = true
    @marc.inventory.set :mines, 0

    assert_no_difference Crate, :count do
    assert_raises(CrateUpgrade::ExplodingCrate_NoMines) do
       Crate.create_and_deposit(@marc, @location, @params)
    end end
  end

  def test_exploding_crate_with_inventory
    @params[:crate][:tools][:mines] = 5
    @params[:upgrade] = {}
    @params[:upgrade][:exploding] = true

    assert_no_difference Crate, :count do
    assert_raises(CrateUpgrade::ExplodingCrate_HasTools) do
       Crate.create_and_deposit(@marc, @location, @params)
    end end
  end

  def test_exploding_crate_underlevel
    @params[:upgrade] = {}
    @params[:upgrade][:exploding] = true
    @marc.user_level.destroyer_cp = 0
    @marc.user_level.save

    assert_no_difference Crate, :count do
    assert_raises(User::InsufficientExperienceError) do
       Crate.create_and_deposit(@marc, @location, @params)
    end end
  end

  def test_exploding_crate_success
    @params[:upgrade] = {}
    @params[:upgrade][:exploding] = true

    crate = nil
    assert_difference Crate, :count do
    assert_difference lambda{@marc.reload.available_pings}, :call, - Upgrade.cached_single('exploding_crate').ping_cost do
    assert_difference lambda{@marc.inventory.reload.mines}, :call, -1 do
      crate = Crate.create_and_deposit(@marc, @location, @params)
    end end end
    assert crate
  end

  # PUZZLE CRATES
  def test_puzzle_crate_underlevel
    @params[:upgrade] = {}
    @params[:upgrade][:locked] = true
    @params[:upgrade][:question] = @QUESTION
    @params[:upgrade][:answer] = @ANSWER

    @marc.user_level.benefactor_cp = 300 #lvl 6, req for puzzle is 7
    @marc.user_level.save

    assert_no_difference CrateUpgrade, :count do
    assert_raises(User::InsufficientExperienceError) do
      Crate.create_and_deposit(@marc, @location, @params)
    end end
  end

  def test_puzzle_crate_no_question
    @params[:upgrade] = {}
    @params[:upgrade][:locked] = true
    @params[:upgrade][:question] = nil
    @params[:upgrade][:answer] = @ANSWER

    assert_no_difference CrateUpgrade, :count do
    assert_raises(CrateUpgrade::PuzzleCrate_NoQuestion) do
      Crate.create_and_deposit(@marc, @location, @params)
    end end
  end

  def test_puzzle_crate_no_pings
    @params[:upgrade] = {}
    @params[:upgrade][:locked] = true
    @params[:upgrade][:question] = @QUESTION
    @params[:upgrade][:answer] = @ANSWER

    @marc.available_pings = 0
    @marc.save

    upgrade = nil
    assert_no_difference CrateUpgrade, :count do
    assert_raises(User::InsufficientPingsError) do
      Crate.create_and_deposit(@marc, @location, @params)
    end end
  end

  def test_puzzle_crate_success
    @params[:crate][:tools][:mines] = 5
    @params[:upgrade] = {}
    @params[:upgrade][:locked] = true
    @params[:upgrade][:question] = @QUESTION
    @params[:upgrade][:answer] = @ANSWER

    crate = nil
    assert_difference(Crate, :count, 1) do
    assert_difference(CrateUpgrade, :count, 1) do
    assert_difference(UpgradeUse, :count, 1) do
      crate = Crate.create_and_deposit(@marc, @location, @params)
    end end end

    assert crate, "Failed to create an Exploding Puzzle Crate"
    assert_equal crate.crate_upgrade.puzzle_question, @QUESTION, "Puzzle Question was not as user specified"
    assert_equal crate.crate_upgrade.puzzle_answer, @ANSWER, "Puzzle Answer was not as user specified"
  end

  # EVER CRATES
  def test_ever_crate
    
  end

  def test_deposit_ever_crate_no_tools
    @params[:crate][:tools][:mines] = 2
    @params[:upgrade] = {}
    @params[:upgrade][:charges] = 5
    # attempt to fill 10 mines with only 8
    @marc.inventory.set :mines, 8

    assert_no_difference Crate, :count do
    assert_raises(CrateUpgrade::EverCrate_TooManyCharges) do
      Crate.create_and_deposit(@marc, @location, @params)
    end end
  end

  def test_deposit_ever_crate_no_dp
    @params[:crate][:datapoints] = 10
    @params[:upgrade] = {}
    @params[:upgrade][:charges] = 5
    # attempt to fill 50 dp with only 40
    @marc.datapoints = 40
    @marc.save

    assert_no_difference Crate, :count do
    assert_raises(CrateUpgrade::EverCrate_TooManyCharges) do
      Crate.create_and_deposit(@marc, @location, @params)
    end end
  end

  def test_deposit_ever_crate_success
    @params[:crate][:datapoints] = 10
    @params[:crate][:tools][:mines] = 2
    @params[:upgrade] = {}
    @params[:upgrade][:charges] = 5

    @marc.datapoints = 50
    @marc.save
    @marc.inventory.set :mines, 10

    crate = nil
    assert_difference lambda{@marc.reload.datapoints}, :call, -50 do
    assert_difference lambda{@marc.inventory.reload.mines}, :call, -10 do
    assert_difference Crate, :count do
      crate = Crate.create_and_deposit(@marc, @location, @params)
    end end end

    assert crate
    assert_equal 10, crate.inventory.datapoints
    assert_equal 2, crate.inventory.mines
    assert_equal 5, crate.charges
  end

  def test_exploding_puzzle_crate_failures
    #FIXME this is going to be more than 1 test eventually
  end

  def test_exploding_puzzle_crate_success
    @params[:upgrade] = {}
    @params[:upgrade][:exploding] = true 
    @params[:upgrade][:locked] = true
    @params[:upgrade][:question] = @QUESTION
    @params[:upgrade][:answer] = @ANSWER

    crate = nil 
    assert_difference lambda{@marc.reload.available_pings}, :call, -(Upgrade.cached_single('exploding_crate').ping_cost + Upgrade.cached_single('puzzle_crate').ping_cost) do
    assert_difference lambda{@marc.inventory.reload.mines}, :call, -1 do
    assert_difference Crate, :count do
    assert_difference CrateUpgrade, :count, 1 do 
    assert_difference UpgradeUse, :count, 2 do 
      crate = Crate.create_and_deposit(@marc, @location, @params)
    end end end end end
    assert crate, "Failed to create an Exploding Puzzle Crate" 
 
    assert_equal crate.crate_upgrade.puzzle_question, @QUESTION, "Puzzle Question was not as user specified" 
    assert_equal crate.crate_upgrade.puzzle_answer, @ANSWER, "Puzzle Answer was not as user specified" 
    assert_equal crate.crate_upgrade.exploding, true, "Failed to specify crate as exploding" 
  end

  def test_ever_puzzle_crate
    #FIXME too
  end

  def test_exploding_ever_crate
  end

  def test_exploding_ever_crate_success
    @params[:upgrade] = {}
    @params[:upgrade][:exploding] = true
    @params[:upgrade][:charges] = 5

    ping_cost = (Upgrade.cached_single('exploding_crate').ping_cost * 5) + Upgrade.cached_single('ever_crate').ping_cost

    crate = nil
    assert_difference Crate, :count do
    assert_difference lambda{@marc.reload.available_pings}, :call, -ping_cost do
    assert_difference lambda{@marc.inventory.reload.mines}, :call, -5 do
      crate = Crate.create_and_deposit(@marc, @location, @params)
    end end end
    assert crate

    assert crate.crate_upgrade.exploding.to_bool
    assert_equal crate.charges, 5
  end

  def test_exploding_ever_puzzle_crate
    #FIXME theres jsut all kinds of wild combinations aren't there.
    # building these is mostly copy paste work i'll do it when i'm feeling more burnt out and can't focus on anything harder -alex
  end

  ############
  # TEST LOOT
  #
  def test_loot
    @suttree.reward_datapoints(500)
    @suttree.inventory.set( :crates, 5 )
    
    assert_difference Crate, :count do
      assert @c = Crate.create_and_deposit(@suttree, @location, { :crate => { :datapoints => 10 } })
    end
    
    assert_difference lambda{@suttree.reload.datapoints}, :call, 10 do
    assert_difference Event, :count do
      assert loot = @c.loot(@suttree)
      assert_equal @suttree.login, loot["user"]
      assert_equal nil, loot["comment"]
    end end
  end

  def test_loot_ever_crate
    params = {}
    params[:crate] = {}
    params[:crate][:datapoints] = 10
    params[:crate][:tools] = {}
    params[:crate][:tools][:mines] = 1
    params[:upgrade] = {}
    params[:upgrade][:charges] = 5

    @marc.datapoints = 50
    @marc.save
    @marc.inventory.set :mines, 5

    crate = Crate.create_and_deposit(@marc, @location, params)

    assert_difference(Event, :count) do # make sure the crate was looted
      crate.loot(@suttree)
    end

    assert_raises(Crate::CrateNotFound) do # make sure the crate is not looted
      crate.loot(@suttree)
    end

    assert_difference(Event, :count) do # make sure someone else can still loot it
      crate.loot(@marc)
    end

    assert_equal crate.reload.charges, 3 # consumed 2 of 5 charges
  end

  def test_loot_expiring_ever_crate_message
    params = {}
    params[:crate] = {}
    params[:crate][:datapoints] = 10
    params[:upgrade] = {}
    params[:upgrade][:charges] = 2

    @marc.datapoints = 50
    @marc.save

    crate = Crate.create_and_deposit(@marc, @location, params)

    assert_difference Event, :count, 1 do # for non-final charges we pmail the crate layer once
      crate.loot(@suttree)
    end

    assert_difference Event, :count, 2 do # if its the last charge, an extra message about expiration should go out to the crate owner
      crate.loot(@marc)
    end
  end

end
