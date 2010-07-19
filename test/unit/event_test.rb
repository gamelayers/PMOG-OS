require File.dirname(__FILE__) + '/../test_helper'

class EventTest < Test::Unit::TestCase
  fixtures :users, :events

  def setup
    super
  end
  
  def test_friendly_events
    @suttree = users(:suttree)
    @marc = users(:marc)
    
    %w(crate_looted mission_completed).each do |context|
      assert_difference(Event, :count) do
        @e = Event.create(:user_id => @suttree.id, :recipient_id => @marc.id, :message => 'oh hai!', :context => context)
        assert @e.valid?
        assert @suttree.events.friendly.find(@e.id)
      end
    end
  end
  
  def test_confrontational_events
    @suttree = users(:suttree)
    @marc = users(:marc)
    
    %w(mine_tripped st_nick_activated mine_deflected).each do |context|
      assert_difference(Event, :count) do
        @e = Event.create(:user_id => @suttree.id, :recipient_id => @marc.id, :message => 'oh hai!', :context => context)
        assert @e.valid?
        assert @suttree.events.confrontational.find(@e.id)
      end
    end
  end
end
