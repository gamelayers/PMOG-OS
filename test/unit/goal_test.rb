require 'test_helper'

class GoalTest < ActiveSupport::TestCase
  fixtures :users, :tools, :locations, :actions, :quests
  
  def test_associations
    qst = quests(:one)
    tool = tools("mines")
    loc = locations("google_com")
    usr = users(:marc)
    act = actions(:perform)
    
    quest = usr.quests.create(:name => "This is a test quest")
    
    goal = quest.goals.build(:user => usr)
    
    goal.tool = tool
    goal.location = loc
    goal.action_id = act.id
    goal.count = 5
    goal.description = "You need to loot five (5) crates to complete this goal."
    
    goal.valid?
    
    goal.errors.each do |e|
      puts e[0] + " " + e[1]
    end
    
    goal.save
    
    quest.goals << goal
    
    quest.save
    
    quest = Quest.find_by_name("This is a test quest");
    
    assert quest.goals.length == 1
    assert quest.goals[0].position == 1
    
  end
  
end
