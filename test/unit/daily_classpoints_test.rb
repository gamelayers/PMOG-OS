require 'test_helper'

class DailyClasspointsTest < ActiveSupport::TestCase
  fixtures :roles, :users, :user_levels, :pmog_classes, :locations, :inventories

  def setup
    @alex = users(:alex)
    @alex.inventory.deposit :mines, 10
    @marc = users(:marc)
    @marc.inventory.deposit :mines, 20
    @loc = locations(:google_com)
    @destroyer = PmogClass.find_by_name('Destroyers')
  end

  def test_it_all
    10.times do
      Mine.create_and_deposit(@alex, {:location_id => @loc.id})
    end
    
    20.times do
      Mine.create_and_deposit(@marc, {:location_id => @loc.id})
    end

    # make sure we got points today
    assert_equal 10*Tool.cached_single(:mines).classpoints, DailyClasspoints.find_by_user_id(@alex.id).points
    assert_equal 20*Tool.cached_single(:mines).classpoints, DailyClasspoints.find_by_user_id(@marc.id).points

    # now lets pretend we did that yesterday
    DailyClasspoints.all do |r|
      r.created_at = r.created_at - 1.day
      r.save
    end

    leaders = DailyClasspoints.leaders_for @destroyer.id

    assert_equal 20*Tool.cached_single(:mines).classpoints, leaders[0].points
    assert_equal 10*Tool.cached_single(:mines).classpoints, leaders[1].points
  end

end
