require File.dirname(__FILE__) + '/../test_helper'

class PreferenceTest < Test::Unit::TestCase
  fixtures :users

  def test_sound_preference
    @user = users(:suttree)
    assert ! @user.preferences.setting('Allow Sound Effects').to_bool
    assert ! @user.preferences.setting(:sound)
    
    @user.preferences.set(:sound, 'on')
    assert ! @user.preferences.setting('Allow Sound Effects').to_bool
    assert @user.preferences.setting(:sound)
    
    @user.preferences.set('Allow Sound Effects', true)
    assert @user.preferences.setting('Allow Sound Effects').to_bool
    assert @user.preferences.setting(:sound)
  end
end
