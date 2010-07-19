# Overlays are what the browser renders in the DOM.
# I refactored a lot of controller code into a module called
# 'overlay system'. Hence this test to check that we reliably
# return the kind of JSON hash that the extension can parse and render.
#
# Add overlays tests in here are you see fit. They can also go in the
# relevant controller, although here we're testing the expected
# contents of the overlay, rather than the entire action, like depoying
# a tool or triggering mine, for example.
require File.dirname(__FILE__) + '/../test_helper'

# Overwrite the login delay so that we don't get told off
# for testing to quickly
class User < ActiveRecord::Base
  def login_delay(seconds = 0)
    0
  end
end

class OverlaySystemTest < ActionController::IntegrationTest
  all_fixtures

  def setup
    super
    @@endpoints = [ 'json' ]
  end

  # A valid login should result in a full JSON hash returned
  def test_login_overlay
    @@endpoints.each do |endpoint|
      post "/session.#{endpoint}", :login => 'justin', :password => 'itsasekrit'
      assert_response :success

      # Do we have a valid user?
      assert session[:user]
      assert ( @user = User.find(@request.session[:user]) )

      # Is the response JSON?
      # Regex from http://blog.inquirylabs.com/2007/05/21/json-decoding-bug-in-rails/
      assert @response.body =~  /"((?:[^\x00-\x1f\\"]|\\(?:u[\da-fA-F]{4}|.))*)"/

      # Now decode the JSON response and check that everything is in order
      json_response = ActiveSupport::JSON.decode(@response.body)
      validate_overlay_contents(@user, json_response)
    end
  end

  def test_invalid_login_overlay
    @@endpoints.each do |endpoint|
      post "/session.#{endpoint}", :login => 'i_do_not_exist', :password => 'who_knows'
      assert ! @request.session[:user]
      assert_raises(ActiveRecord::RecordNotFound) do
        User.find(@request.session[:user])
      end
    end
  end

  def test_mine_overlay
    @@endpoints.each do |endpoint|
      post "/session.#{endpoint}", :login => 'justin', :password => 'itsasekrit'

      @user = User.find(@request.session[:user])
      @user.inventory.set( :mines, 10 )
      @location = Location.find :first

      post "/locations/#{@location.id}/mines.#{endpoint}"
      assert_response 201
      assert @response.body =~  /"((?:[^\x00-\x1f\\"]|\\(?:u[\da-fA-F]{4}|.))*)"/

      json_response = ActiveSupport::JSON.decode(@response.body)
      validate_overlay_contents(@user, json_response)

      # Views and inventory checks
      assert_equal 9, @user.inventory.mines
      assert_equal 9, json_response['user']['mines']
      assert json_response['flash']['notice'] =~ /Mine laid!/i
    end
  end

  protected

  # Check for the basic features in an overlay hash
  def validate_overlay_contents(user, json_response)
    #puts json_response.inspect

    # Meta data
    assert json_response['user']['authenticity_token']
    assert_equal PMOG_EXTENSION_VERSION, json_response['version']

    # User data
    assert_equal 'justin', json_response['user']['login']
    assert_equal user.remember_token, json_response['user']['auth_token']

    # Inventory and equipped items
    assert_equal user.inventory.reload.mines, json_response['user']['mines']
    assert_equal user.is_armored?, json_response['user']['armored']

    # Preferences
    assert_equal user.preferences.setting('Allow Sound Effects'), json_response['user']['sound_preference']
    assert_equal user.preferences.setting('Extension Skin'), json_response['user']['skin']
  end
end
