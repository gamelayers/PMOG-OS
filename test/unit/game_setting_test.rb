require File.dirname(__FILE__) + '/../test_helper'

class GameSettingTest < ActiveSupport::TestCase
  def test_value_must_be_present
    g1 = GameSetting.create( :key => 'test one' )
    g2 = GameSetting.create( :key => 'test two', :value => 2 )
    assert ! g1.valid?
    assert g2.valid?
  end

  def test_key_must_be_unique
    g1 = GameSetting.create( :key => 'test one', :value => 1 )
    g2 = GameSetting.create( :key => 'test one', :value => 2 )
    assert g1.valid?
    assert ! g2.valid?
  end
end
