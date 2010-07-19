require File.dirname(__FILE__) + '/../test_helper'

class GiftcardTest < Test::Unit::TestCase
  fixtures :users, :giftcards, :locations, :abilities
  
  def setup
    super
    @marc = users(:marc)
    @duncan = users(:suttree)
    @location  = locations(:yeah_com)
    @params = { 
      :location_id => @location.id
    }
  end
  
  def test_create_and_deposit
    #FAILURE CASES
    # no dp
    @marc.datapoints = 0
    assert_raises(User::InsufficientDPError) do
      Giftcard.create_and_deposit(@marc, @params)
    end

    # no location
    @bad_params = {
      :location_id => "bad location id"
    }
    assert_raises(Location::LocationNotFound) do 
      Giftcard.create_and_deposit(@marc, @bad_params)
    end

    #SUCCESS CASE
    @marc.datapoints = Ability.cached_single(:giftcard).value
    @card = Giftcard.create_and_deposit(@marc, @params)
    assert !@card.nil?
  end

  def test_loot
    @card = giftcards(:sample_card)

    assert_difference(Event, :count) do
      starting_dp = @duncan.datapoints
      @card.loot(@duncan)
      assert_equal @duncan.reload.datapoints, starting_dp + Ability.cached_single(:giftcard).value
    end
  end

end
