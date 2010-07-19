require File.dirname(__FILE__) + '/../test_helper'

class BrowserStatTest < ActiveSupport::TestCase
  # Make sure we can create a simple browser stat row, and make sure that
  # we don't duplicate rows when nothing has changed
  def test_creation
    @user = User.find :first
    args = { :user_id => @user.id, :os => "Windows", :browser_name => "Firefox", :browser_version => "2.0" }
    
    count = BrowserStat.count
    BrowserStat.create(args) unless BrowserStat.exists?(args)
    assert_equal count + 1, BrowserStat.count
    
    count = BrowserStat.count
    BrowserStat.create(args) unless BrowserStat.exists?(args)
    assert_equal count, BrowserStat.count
  end
  
  # Test we can create a new row when something changes
  def test_changes
    @user = User.find :first
    args = { :user_id => @user.id, :os => "Windows", :browser_name => "Firefox", :browser_version => "2.0" }
    
    # Should increment
    count = BrowserStat.count
    BrowserStat.create(args) unless BrowserStat.exists?(args)
    assert_equal count + 1, BrowserStat.count
    
    # Nothing changes, should not increment
    count = BrowserStat.count
    BrowserStat.create(args) unless BrowserStat.exists?(args)
    assert_equal count, BrowserStat.count
    
    # Version changes, should increment
    args = { :user_id => @user.id, :os => "Windows", :browser_name => "Firefox", :browser_version => "3.0" }
    count = BrowserStat.count
    BrowserStat.create(args) unless BrowserStat.exists?(args)
    assert_equal count + 1, BrowserStat.count
    
    # User changes, should also increment
    @user = User.find_by_login 'marc'
    args = { :user_id => @user.id, :os => "Windows", :browser_name => "Firefox", :browser_version => "3.0" }
    count = BrowserStat.count
    BrowserStat.create(args) unless BrowserStat.exists?(args)
    assert_equal count + 1, BrowserStat.count
  end
end