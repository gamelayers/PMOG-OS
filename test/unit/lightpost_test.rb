require File.dirname(__FILE__) + '/../test_helper'

class LightpostTest < Test::Unit::TestCase
  fixtures :users, :user_levels, :inventories, :upgrades, :locations, :lightposts
  
  def setup
    super
    # marc already has some lightposts
    # also some pings
    # also lvl 20 everything
    @marc = users(:marc)

    @location  = locations(:yeah_com)

    @params = { 
      :lightpost => { :tags=>"", :description=>""},
      :location_id => @location.id
    }

    @puzzle_params = {
      :upgrade => { :puzzle => true, :question => "ping?", :answer => "pong!" },
      :lightpost => { :tags=>"", :description=>""},
      :location_id => @location.id
    }
  end
    
  def test_create_success
    assert_difference lambda{@marc.inventory.reload.lightposts}, :call, -1 do
    assert_difference Lightpost, :count do
      @lightpost = Lightpost.create_and_deposit @marc, @params
    end end
    assert @lightpost.valid?
  end
  
  def test_create_and_deposit_empty_params
    assert_no_difference lambda{@marc.inventory.reload.lightposts}, :call do
    assert_no_difference Lightpost ,:count do
    assert_raise Location::InvalidLocation do
      Lightpost.create_and_deposit @marc, {}
    end end end
  end
  
  def test_create_and_deposit_bad_location_id
    assert_no_difference lambda{@marc.inventory.reload.lightposts}, :call do
    assert_no_difference Lightpost ,:count do
    assert_raise Location::LocationNotFound do
      Lightpost.create_and_deposit @marc, @params.merge({ :location_id => 'bad_url'})
    end end end
  end
  
  def test_create_and_deposit_not_enough_lightposts
    @marc.inventory.set :lightposts, 0

    assert_no_difference lambda{@marc.inventory.reload.lightposts}, :call do
    assert_no_difference Lightpost, :count do
    assert_raise User::InventoryError do
        @lightpost = Lightpost.create_and_deposit @marc, @params
    end end end
  end


  def test_create_puzzle_no_pings
    @marc.available_pings = 0
    @marc.save

    assert_no_difference lambda{@marc.inventory.reload.lightposts}, :call do
    assert_no_difference Lightpost, :count do
    assert_no_difference Puzzle, :count do
    assert_raise User::InsufficientPingsError do
        @lightpost = Lightpost.create_and_deposit @marc, @puzzle_params
    end end end end
  end

  def test_create_puzzle_under_level
    @marc.user_level.pathmaker_cp = 0
    @marc.user_level.save

    assert_no_difference lambda{@marc.inventory.reload.lightposts}, :call do
    assert_no_difference Lightpost, :count do
    assert_no_difference Puzzle, :count do
    assert_raise User::InsufficientExperienceError do
        @lightpost = Lightpost.create_and_deposit @marc, @puzzle_params
    end end end end
  end

  def test_create_puzzle_no_question
    assert_no_difference lambda{@marc.inventory.reload.lightposts}, :call do
    assert_no_difference Lightpost, :count do
    assert_no_difference Puzzle, :count do
    assert_raise Lightpost::NoQuestionError do
        @lightpost = Lightpost.create_and_deposit @marc, @puzzle_params.merge({:upgrade => {:puzzle => true, :answer => "ut oh"}})
    end end end end
  end

  def test_create_puzzle_success
    assert_difference lambda{@marc.inventory.reload.lightposts}, :call, -1 do
    assert_difference lambda{@marc.reload.available_pings}, :call, -Upgrade.cached_single('puzzle_post').ping_cost do
    assert_difference Lightpost, :count do
    assert_difference Puzzle, :count do
        @lightpost = Lightpost.create_and_deposit @marc, @puzzle_params
    end end end end
  end

end
