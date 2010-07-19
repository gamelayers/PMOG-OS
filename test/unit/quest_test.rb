require 'test_helper'

class QuestTest < ActiveSupport::TestCase
  fixtures :quests

  def test_association_validity
    quest = quests(:one)
    
    quest.valid?
    
    quest.errors.each do |e|
      puts e[0] + " " + e[1]
    end
    
    assert quest.valid?
    
    quest = quests(:two)
    
    assert !quest.valid?
  end
  
  def test_name_validation
    user = User.find(:first)
    
    quest = user.quests.new
    
    assert !quest.valid?, "The Quest model should raise an invalid error if the name isn't set"
    assert_equal "can't be blank", quest.errors.on(:name)
  end
end
