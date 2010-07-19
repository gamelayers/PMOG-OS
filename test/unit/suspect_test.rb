require File.dirname(__FILE__) + '/../test_helper'

class SuspectTest < ActiveSupport::TestCase
  fixtures :users

  def setup
    super
  end

  def test_track
    visits = 5
    timestamp = Date.today.to_s
    remote_addr = "158.152.1.58"
    current_user = User.find :first

    # This should create a new record
    suspect = Suspect.track( current_user, visits, timestamp, remote_addr )
    assert_equal 1, Suspect.count

    # This should re-use the existing record
    visits += 1
    suspect = Suspect.track( current_user, visits, timestamp, remote_addr )
    assert_equal 1, Suspect.count
    
    # This should create a new record too
    timestamp = Date.tomorrow.to_s
    suspect = Suspect.track( current_user, visits, timestamp, remote_addr )
    assert_equal visits, suspect.visits
    assert_equal 2, Suspect.count
  end
end
