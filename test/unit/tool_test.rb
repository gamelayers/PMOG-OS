require File.dirname(__FILE__) + '/../test_helper'

class ToolTest < Test::Unit::TestCase
  fixtures :users, :tools
  
  def setup
    super
    @marc = users(:marc)
    @suttree = users(:suttree)
  end

# this isn't how we charge things anymore  
#  def test_lowest_price
#    @mine = tools('mines')
#    @portal = tools('portals')
#    @st_nick = tools('st_nicks')
#    
#    # Marc is a level 10 Seer, Benefactor, Destroyer
#    # Marc should only get a discount for his assocations
#    assert_equal 1, @mine.lowest_cost_for(@marc)
#    assert_equal 1, @portal.lowest_cost_for(@marc)
#    assert_equal 10, @st_nick.lowest_cost_for(@marc)
#    
#    # Suttree is a level 1 Shoat 
#    # Suttree should get the cheapest price for all his tools
#    @mine.lowest_cost_for(@suttree)
#    assert_equal 1, @mine.lowest_cost_for(@suttree)
#    assert_equal 1, @portal.lowest_cost_for(@suttree)
#    assert_equal 1, @st_nick.lowest_cost_for(@suttree)
#    
#    # Now make Marc a level 2 and all the tools should be cheap again.
#    @marc.update_attribute(:current_level,2)
#    assert_equal 1, @mine.lowest_cost_for(@marc)
#    assert_equal 1, @portal.lowest_cost_for(@marc)
#    assert_equal 1, @st_nick.lowest_cost_for(@marc)    
#  end

end
