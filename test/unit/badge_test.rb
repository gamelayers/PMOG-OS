require File.dirname(__FILE__) + '/../test_helper'

class BadgeTest < Test::Unit::TestCase
  fixtures :badges

  # Testing the switch from habtm to hmt
  def test_badges_users
    @user = User.find :first
    @badge = Badge.find :first
    
    # Make sure this badge has no users and no badgings
    @badge.users = []
    Badging.destroy_all
    assert_equal [], @badge.users
    assert_equal [], Badging.find(:all)

    # Now assign a user and make sure everything lines up
    @badge.users << @user
    assert_equal @badge.users.size, 1
    assert_equal Badging.find(:first).created_at.to_date, Time.now.utc.to_date
  end
end
