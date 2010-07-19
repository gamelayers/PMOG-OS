require File.dirname(__FILE__) + '/../test_helper'

class UserObserverTest < Test::Unit::TestCase
  fixtures :all

  def setup
    # Not sure why we have to set this again here, but it's
    # getting reset to :smtp somewhere along the line
    ActionMailer::Base.delivery_method = :test
  end

  def test_creation
    user = User.new( :login => 'jose', :password => 'seekrit', :password_confirmation => 'seekrit', :email => 'duncan.gough+jose@gmail.com', "date_of_birth(1i)" => '1975', "date_of_birth(2i)" => '2', "date_of_birth(3i)" => '23' )
    assert user.save

    assert user.errors.empty?
    assert_equal "shoat", user.user_level.primary_class

    assert_equal 30, user.inventory.lightposts
    assert_equal 10, user.inventory.portals
    assert_equal 10, user.inventory.armor
    assert_equal 10, user.inventory.st_nicks
    assert_equal 10, user.inventory.mines

    assert_equal 'classic', user.preferences.setting("Extension Skin")
    assert_equal 'false', user.preferences.setting("Allow Sound Effects")
    assert_equal 'false', user.preferences.setting("Allow NSFW Content")
    assert_equal '3', user.preferences.setting("The Nethernet Mission Content Quality Threshold")
    assert_equal '3', user.preferences.setting("The Nethernet Portal Content Quality Threshold")

    assert_equal 2, user.beta_keys.size
  end
end
