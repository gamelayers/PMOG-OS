require File.dirname(__FILE__) + '/../test_helper'
require 'queued_mission_controller'

# Re-raise errors caught by the controller.
class QueuedMissionController; def rescue_action(e) raise e end; end

class QueuedMissionControllerTest < ActionController::TestCase
  include QueuedMissionHelper
  fixtures :users, :missions
  
  def setup
    super
    @user = users(:suttree)
    @mission = missions(:pmog_only_mission)
  end
  
  def test_create
    login_as :suttree
    get :create, :id => @mission.url_name
    assert_response :redirect
    assert_redirected_to mission_url(@mission.url_name)
    assert_equal "Saved mission for later", flash[:notice]
  end

  # Test the conditional GET of queued missions
  # - should return a 200
  def test_poll_for_new_queued_mission
    @user = User.find_by_login('suttree')
    @mission = Mission.find(:first)
    login_as :suttree

    # Clear the queued missions and then add one to the queue
    @user.queued_missions = []
    QueuedMission.deposit(@user, @mission)
    queue_size = @user.queued_missions.size
    
    # Now ping for the Queued Missions, we should get a 200
    get :index, { :format => 'json' }
    assert_equal @response.headers['Status'], '200 OK'
    assert @response.body =~ /#{@mission.name}/
  end

  # Test the conditional GET of queued missions
  # - should return a 304
  def test_poll_for_no_new_queued_missions
    @user = User.find_by_login('suttree')
    @mission = Mission.find(:first)
    login_as :suttree
    
    # Poll and we should receive a 304
    @request.env['HTTP_IF_MODIFIED_SINCE'] = @mission.created_at.httpdate
    get :index, { :format => 'json' }

    assert_equal @response.headers['Status'], '304 Not Modified'
    assert_equal @response.headers['PMOG_304'], true
    assert @response.body.blank?
  end
end
