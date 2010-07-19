require File.dirname(__FILE__) + '/../test_helper'
require 'messages_controller'

# Re-raise errors caught by the controller.
class MessagesController; def rescue_action(e) raise e end; end
  
class MessagesControllerTest < ActionController::TestCase
  fixtures :users, :tools, :pings
  
  def setup
    super
  end
  
  # Test that pinging the messaging api results in some daily
  # and hourly activity stats being recorded
  def test_messaging_api
    @user = User.find_by_login('suttree')
    login_as :suttree

    hourly_activity_count = HourlyActivity.count
    daily_activity_count = DailyActivity.count

    get :index, { :format => "js", :user_id => @user.login, :version => PMOG_EXTENSION_VERSION }

    assert_equal (hourly_activity_count + 1), HourlyActivity.count
    assert_equal (daily_activity_count + 1), DailyActivity.count
    
    # Make sure that a subsequent ping won't increment the counters
    hourly_activity_count = HourlyActivity.count
    daily_activity_count = DailyActivity.count

    get :index, { :format => "js", :user_id => @user.login, :version => PMOG_EXTENSION_VERSION }
    
    assert_equal hourly_activity_count, HourlyActivity.count
    assert_equal daily_activity_count, DailyActivity.count
  end

  # Create a new messages and test that it can be picked up
  # by the extension correctly. This should hopefully catch
  # the damned ActionController::DoubleRenderError
  def test_message_delivery
    @user = User.find_by_login('suttree')
    @user.reward_datapoints(100)
    @num_messages = @user.messages.size
    login_as :suttree

    # Create a message
    post :create, { :format => 'json', :user_id => @user.login, :pmail_message =>'@suttree hi there' }
    assert_equal @num_messages + 1, @user.reload.messages.size
    
    post :create, { :format => 'json', :user_id => @user.login, :pmail_message => '@suttree 1'}
    assert_equal @num_messages + 2, @user.reload.messages.size
    
    # Check to see if the code throws a 304 as we're a bad version of the extension
    get :index, { :format => "json", :user_id => @user.login }
    assert_equal @response.headers['Status'], '304 Not Modified'
    
    # Now poll for the message as a valid version of the extension
    get :index, { :format => "json", :user_id => @user.login, :version => PMOG_EXTENSION_VERSION }
    assert_equal @response.headers['Status'], '200 OK'
    assert @response.body =~ /hi there/
  end
  
  # Test creating a message where the user does not have enough DP
  def test_invalid_create
    @user = User.find_by_login('suttree')
    @user.datapoints = 0
    @user.save
    login_as :suttree

    # No new messages should be created, as we don't have enough DP
    @num_messages = @user.messages.size

    post :create, { :format => 'json', :user_id => @user.login, :pmail_message => '@suttree hi there' }

    assert_equal @num_messages, @user.reload.messages.size # no change
		assert_response 422
    assert_equal flash[:error], "Sorry, you don't have enough datapoints to send messages to 1 players"
  end

  # Test creating a message where the user has enough DP
  def test_valid_create
    @user = User.find_by_login('suttree')
    login_as :suttree

    @user.reward_datapoints(100)
    @num_messages = @user.messages.size
    post :create, { :format => 'json', :user_id => @user.login, :pmail_message =>'@suttree hi there' }
    
    json_response = ActiveSupport::JSON.decode(@response.body)
    
    # should include effects to call after the overlay renders.
    assert json_response[ "flash" ]["notice"] =~ /Message sent!/
    #assert_equal 'wait_then_fade', json_response['messages'].first['post']
    
    # Message array should not be empty
    assert_equal @num_messages + 1, @user.reload.messages.size

    assert @response.body =~ /Message sent/
    assert_response 201
  end
  
  def test_create_bad_params
    @user = User.find_by_login('suttree')
    login_as :suttree
    
    # Missing required params
    post :create, { :format => 'json', :user_id => @user.login, :pmail_message => " " }
    
    # Errors array should not be empty
    # assert @response.body !~ /"errors": \[\]/
    # assert @response.body =~ /You cannot send an empty message/
    # assert_response :success
		assert_response 422
		json_response = ActiveSupport::JSON.decode(@response.body)
		assert json_response[ "flash" ]["error"] =~ /Please provide a message to send/
  end
  
  def test_create_with_unknown_recipient
    @user = User.find_by_login('suttree')
    login_as :suttree
    
    # Unknown user
    post :create, { :format => 'json', :user_id => @user.login, :pmail_message => '@theGOMP greetings' }
    
    # Errors array should not be empty
		json_response = ActiveSupport::JSON.decode(@response.body)
		assert_equal "Couldn't find a user with the login thegomp", json_response[ "flash" ]["error"]
    assert_response 422
    
    # Incorrect Format
    post :create, { :format => 'json', :user_id => @user.login, :pmail_message => 'theGOMP greetings' }
    
    # Errors array should not be empty
    # assert @response.body !~ /"errors": \[\]/
    # assert @response.body =~ /No recipient found; specify a recipient like this @some_player./
    # assert_response :success
		json_response = ActiveSupport::JSON.decode(@response.body)
		assert json_response[ "flash" ]["error"] =~ /Please add at least one @recipient but not more than five./
    assert_response 422
  end
    
  def test_create_onetime_upgrade_message_per_version
    @user = User.find_by_login('suttree')
    @user.reward_datapoints(100)
    login_as :suttree

    # Poll for the message without a version number.
    # There should be no upgrade message returned.
    get :index, { :format => "json", :user_id => @user.login }
    assert_equal @response.headers['Status'], '304 Not Modified'
    
    # Now poll for messages as a valid version of the extension with the current version number.
    # There should be no upgrade notice
    get :index, { :format => "json", :user_id => @user.login, :version => PMOG_EXTENSION_VERSION }
    assert_equal @response.headers['Status'], '200 OK'
        
    # Now poll for the message as a valid version of the extension with a very high version number.
    # There should be no upgrade message returned.
    get :index, { :format => "json", :user_id => @user.login, :version => '10000000000000.412' }
    assert_equal @response.headers['Status'], '200 OK'
    
    # Now poll for messages as a valid version of the extension with a very low version number.
    # However the version must be higher than the Buggy version of the extension 0.408
    # There should be an upgrade notice
    get :index, { :format => "json", :user_id => @user.login, :version => '0.409' }

    assert_equal @response.headers['Status'], '200 OK'
    json_response = response_to_json
    message = ActiveSupport::JSON.decode(json_response["messages"].first["body"])
    assert message['content'] =~ /There's a new Nethernet extension!/
    
    # Now poll for messages as the same deprecated extension and ensure you don't see the same 
    # message we dismissed.
    get :index, { :format => "json", :user_id => @user.login, :version => '0.409' }
    assert_equal @response.headers['Status'], '200 OK'
  end
  
  def test_summon
    @user = User.find_by_login('suttree')
    @user.reward_datapoints(100)
    @summoned = User.find_by_login('marc')
    @page = Location.find_or_create_by_url('http://www.google.com')
    login_as :suttree
    
    post :summon, { :format => "json", :user_id => @user.login, :summoned => '@'+@summoned.login, :location_id => @page.id }
    json_response = response_to_json
    
    assert assigns['messages'].first.context == 'summon'
    assert_equal "Success, you summoned #{@summoned.login} to #{@page.url}.", json_response["flash"]["notice"]
    
    post :summon, { :message =>"optinal message!", :format => "json", :user_id => @user.login, :summoned => '@'+@summoned.login, :location_id => @page.id }
    json_response = response_to_json
    assert assigns['messages'].first.context == 'summon'
    assert assigns['messages'].first.body == 'optinal message!'
    assert_equal "Success, you summoned #{@summoned.login} to #{@page.url}.", json_response["flash"]["notice"]
  end
  
  def test_summon_bad_params
    @user = User.find_by_login('suttree')
    @user.reward_datapoints(100)
    @summoned = User.find_by_login('marc')
    @page = Location.find_or_create_by_url('http://www.google.com')
    login_as :suttree
    
    # Missing summoned param
    post :summon, { :format => "json", :user_id => @user.login }
    json_response = response_to_json
    assert_equal "Please add at least one @recipient but not more than five.", json_response["flash"]["error"]
    assert_equal @response.headers['Status'], '422 Unprocessable Entity'
    
    # Invalid summoned login
    post :summon, { :format => "json", :user_id => @user.login, :summoned => 'bad login' }
    json_response = response_to_json
    assert_equal "Please add at least one @recipient but not more than five.", json_response["flash"]["error"]
    assert_equal @response.headers['Status'], '422 Unprocessable Entity'
    
    # Missing Location
    post :summon, { :format => "json", :user_id => @user.login, :summoned => '@'+@summoned.login }
    json_response = response_to_json
    assert_equal json_response["flash"]["error"], "The player could not be summoned because we could not find the page you are on."
    assert_equal @response.headers['Status'], '422 Unprocessable Entity'

    # Invalid Location
    post :summon, { :format => "json", :user_id => @user.login, :summoned => '@'+@summoned.login, :location_id => 'some bad id' }
    json_response = response_to_json
    assert_equal json_response["flash"]["error"], "The player could not be summoned because we could not find the page you are on."
    assert_equal @response.headers['Status'], '422 Unprocessable Entity'
    
  end
  
  def test_summoned
    @user = User.find_by_login('suttree')
    @user.reward_datapoints(100)
    @page = Location.find_or_create_by_url('http://www.google.com')
    login_as :suttree
    
    post :summon, { :format => "json", :user_id => @user.login, :summoned => '@'+@user.login, :location_id => @page.id }
    json_response = response_to_json
    assert assigns['messages'].first.context == 'summon'
    assert_equal "Success, you summoned #{@user.login} to #{@page.url}.", json_response["flash"]["notice"]
    
    # Now poll for the message to see if the summons arrives.
    get :index, { :format => "json", :user_id => @user.login, :version => PMOG_EXTENSION_VERSION }
    assert_equal @response.headers['Status'], '200 OK'
    
    json_response = response_to_json
    message = ActiveSupport::JSON.decode(json_response["messages"].first["body"])
    assert message["url"] == @page.url
    
    # Mark that message as read
    put :read, { :format => "json", :id => message['id'] }
    assert_equal @response.headers['Status'], '200 OK'

    # Now take the summons 
    post :summoned, { :format => "json", :user_id => @user.login, :id => message["id"] }
    assert_equal @response.headers['Status'], '201 Created'
    json_response = response_to_json
    assert json_response["flash"]["notice"] == "Summons confirmation sent"
    
    # Now poll again and see if we get the summons confirmation.
    @user.messages.clear_cache
    get :index, { :format => "json", :user_id => @user.login, :version => PMOG_EXTENSION_VERSION }
    assert_equal @response.headers['Status'], '200 OK'
    json_response = response_to_json
    message = ActiveSupport::JSON.decode(json_response["messages"].first["body"])
    assert message["content"] == "#{@user.login} has accepted your summons and traveled to #{@page.url}!"
    assert message["context"] == "summon_confirmation"

    # Mark that message as read
    put :read, { :format => "json", :id => message['id'] }
    assert_equal @response.headers['Status'], '200 OK'
    
    # Now poll again and see if we get the summons receipt
    get :index, { :format => "json", :user_id => @user.login, :version => PMOG_EXTENSION_VERSION }
    assert_equal @response.headers['Status'], '200 OK'
    json_response = response_to_json
    message = ActiveSupport::JSON.decode(json_response["messages"].first["body"])

    assert message["content"] == "You have followed a summons to #{@page.url} by #{@user.login}"
    assert message["context"] == "summon_receipt"
  end
  
  def test_summoned_bad_params
    @user = User.find_by_login('suttree')
    login_as :suttree

    # Now take the summons 
    post :summoned, { :format => "json", :user_id => @user.login, :id => 'bogus id' }
    assert_equal @response.headers['Status'], '422 Unprocessable Entity'    
  end
end
