require File.dirname(__FILE__) + '/../test_helper'

class LevelTest < Test::Unit::TestCase
  fixtures :users, :levels

  def setup
    super
  end

  def test_level_req_function
    21.times do |cp_lvl|
      next if cp_lvl == 0
      21.times do |dp_lvl|
        next if dp_lvl == 0
        real_level = (cp_lvl < dp_lvl) ? cp_lvl : dp_lvl
        min_cp = Level.req(cp_lvl, :cp)
        min_dp = Level.req(dp_lvl, :dp)
        # test values inside the range
        assert_equal real_level, Level.calculate_single(min_cp + 5, min_dp + 5)
        # test values on the border
        assert_equal real_level, Level.calculate_single(min_cp, min_dp)
      end
    end
  end

end
