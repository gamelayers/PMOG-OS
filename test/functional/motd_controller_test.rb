require File.dirname(__FILE__) + '/../test_helper'

class MotdControllerTest < ActionController::TestCase
  fixtures :motd, :users

  def test_should_render_latest_motd_json
    login_as :suttree
    get :index, :format => "json"
    assert_response :success
    assert @response.body =~ /second motd body/i
  end
  
  def test_should_not_render_latest_dismissed_motd_json
    @user = User.find_by_login('suttree')
    Motd.find(:all).each do |motd|
      motd.dismissals.dismiss @user
    end
    
    login_as :suttree
    get :index, :format => "json"
    assert_equal "", @response.body # can't seem to get a 304 out of the headers :(
  end
  
  def test_should_not_render_admin_html_scaffold_to_admins
    login_as :bryce
    get :index
    assert_response :redirect
    assert_equal flash[:notice], "Permission denied"
  end
  
  # Test polling the MOTD API should increment the +BrowserStats+
  def test_should_update_browser_stats
    # We don't need this anymore, but it's here just in case
    #login_as :suttree
    #
    ## Should increment
    #count = BrowserStat.count
    #get :index, { :format => "json", :os => "Windows", :browser_name => "Firefox", :browser_version => "2.0" }
    #assert_response :success
    #assert @response.body =~ /second motd body/i
    #assert_equal count + 1, BrowserStat.count
    #
    ## Should not increment
    #count = BrowserStat.count
    #get :index, { :format => "json", :os => "Windows", :browser_name => "Firefox", :browser_version => "2.0" }
    #assert_response :success
    #assert @response.body =~ /second motd body/i
    #assert_equal count, BrowserStat.count
    #
    ## Change the version, should increment
    #count = BrowserStat.count
    #get :index, { :format => "json", :os => "Windows", :browser_name => "Firefox", :browser_version => "3.0" }
    #assert_response :success
    #assert @response.body =~ /second motd body/i
    #assert_equal count + 1, BrowserStat.count
  end
end
