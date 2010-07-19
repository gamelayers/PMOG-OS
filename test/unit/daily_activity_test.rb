require File.dirname(__FILE__) + '/../test_helper'

class DailyActivityTest < ActiveSupport::TestCase
  fixtures :users

  def setup
    super
  end

  def test_record
    # Test multiple pings don't increment row counts per day
    user = User.find :first
    version = "0.403"
    
    # First hit should create a row
    activity_count = DailyActivity.count
    DailyActivity.record(user, version, Date.today.to_s)
    assert_equal activity_count + 1, DailyActivity.count
  
    # Subsequent hits shouldn't increment today
    activity_count = DailyActivity.count
    DailyActivity.record(user, version, Date.today.to_s)
    assert_equal activity_count, DailyActivity.count

    version = "0.404"
    # But a change in version should be recorded
    activity_count = DailyActivity.count
    DailyActivity.record(user, version, Date.today.to_s)
    assert_equal activity_count + 1, DailyActivity.count
  end
end
