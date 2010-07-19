require File.dirname(__FILE__) + '/../test_helper'

class BadgeTest < Test::Unit::TestCase
  fixtures :users, :locations
  
  def test_is_tested
    user = User.find(:first)
    location = Location.find(:first)
    
    branch = Branch.new(:location_id => location.id)
    branch.user = user
    
    assert_equal false, branch.tested
    
    branch.tested = true
    
    assert_equal true, branch.tested
  end
  
end