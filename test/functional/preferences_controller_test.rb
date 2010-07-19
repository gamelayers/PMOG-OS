require File.dirname(__FILE__) + '/../test_helper'

require 'preferences_controller'
# Re-raise errors caught by the controller.
class PreferencesController; def rescue_action(e) raise e end; end

class PreferencesControllerTest < Test::Unit::TestCase
  fixtures :users
  
  def setup
    @controller = PreferencesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @controller.instance_eval do
      def current_user
        User.find_by_login('suttree')
      end
    end
  end
    
  def test_should_update_preferences_for_the_extension
    prefs = { :foo => 'bar', :bar => 'baz', :baz => 'foo' }
    @current_user = users(:suttree)
    @request.session[:user] = @current_user.id
    assert_difference @current_user.preferences, :size, 3 do
      put :update, :format => 'ext', :preferences => prefs
      assert_redirected_to hud_path(:format => 'ext')
      
      @current_user.preferences(true).each do |p|
        assert prefs.keys.include?(p.name.to_sym)
        assert prefs.values.include?(p.value)
      end
    end  
  end
  
  def test_sound_off
    current_user = users(:suttree)
    
    # default setting is off
    assert @controller.sound_off?

    # one on one off, should default to on
    current_user.preferences.set(:sound, 'on')
    current_user.preferences.set( 'Allow Sound Effects', false)
    assert !@controller.sound_off?

    # one off one on, should default to on
    current_user.preferences.set(:sound, 'off')    
    current_user.preferences.set( 'Allow Sound Effects', true)
    assert !@controller.sound_off?

    # both off, should be off
    current_user.preferences.set( 'Allow Sound Effects', false)
    current_user.preferences.set(:sound, 'off')
    assert @controller.sound_off?

    # both on, should be on
    current_user.preferences.set( 'Allow Sound Effects', true)
    current_user.preferences.set(:sound, 'on')
    assert ! @controller.sound_off?
  end
end
