require 'test_helper'

class UserActivityTest < ActiveSupport::TestCase
  fixtures :users, :game_settings

  def setup
    @alex = users(:alex)
  end

  def test_rewards_datapoints_with_nil_paycheck
    @alex.paycheck_at = nil
    @alex.save

    dp = @alex.datapoints

    UserActivity::update(@alex, '0.0.0')

    assert dp < @alex.reload.datapoints
  end

  def test_rewards_datapoints_after_paycheck_due
    @alex.paycheck_at = Time.now.utc
    @alex.save

    dp = @alex.datapoints

    UserActivity::update(@alex, '0.0.0')

    assert dp < @alex.reload.datapoints
  end

  def test_doesnt_reward_datapoints_before_paycheck_due
    @alex.paycheck_at = Time.now.utc + 5.seconds
    @alex.save

    dp = @alex.datapoints

    UserActivity::update(@alex, '0.0.0')

    assert_equal dp, @alex.reload.datapoints
  end

  def test_next_paycheck_isnt_for_an_hour
    right_now = Time.now.utc

    sleep(1)

    @alex.paycheck_at = right_now
    @alex.save

    UserActivity::update(@alex, '0.0.0')

    assert right_now + 1.hour < @alex.reload.paycheck_at
  end

end
