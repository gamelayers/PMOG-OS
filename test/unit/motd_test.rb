require File.dirname(__FILE__) + '/../test_helper'

class MotdTest < ActiveSupport::TestCase
  fixtures :motd

  def test_latest
    motd = motd(:first)
    assert_equal motd.title, 'first motd title'
    assert_equal motd.body, 'first motd body'
  end
end