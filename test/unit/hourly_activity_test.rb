require File.dirname(__FILE__) + '/../test_helper'

class HourlyActivityTest < ActiveSupport::TestCase
  fixtures :users

  def setup
    super
  end

  def test_record
    # Test multiple pings don't increment row counts per day
    user = User.find :first
    version = "0.412"
    
    # First hit should create a row
    activity_count = HourlyActivity.count
    HourlyActivity.record(user, version, Date.today.to_s, Time.now.hour.to_s)
    assert_equal activity_count + 1, HourlyActivity.count
  
    # Subsequent hits shouldn't increment today
    activity_count = HourlyActivity.count
    HourlyActivity.record(user, version, Date.today.to_s, Time.now.hour.to_s)
    assert_equal activity_count, HourlyActivity.count

    version = "0.413"
    # But a change in version should be recorded
    activity_count = HourlyActivity.count
    HourlyActivity.record(user, version, Date.today.to_s, Time.now.hour.to_s)
    assert_equal activity_count + 1, HourlyActivity.count
  end

  # Make sure the user's timezone doesn't get messed up
  def test_timezone
    user = User.find :first
    version = "0.412"
    timezone = user.tz
    HourlyActivity.record(user, version, Date.today.to_s, Time.now.hour.to_s)
    assert_equal timezone, user.tz
  end
end