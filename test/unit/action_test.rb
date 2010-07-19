require 'test_helper'

class ActionTest < ActiveSupport::TestCase
  fixtures :actions

  def test_type_attribute
    action = actions(:action_valid_type)
    
    assert action.valid?
    
    action = actions(:action_invalid_type)
    
    assert !action.valid?
  end
end
