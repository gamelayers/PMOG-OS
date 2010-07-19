# == Schema Information
# Schema version: 20081220201004
#
# Table name: faves
#
#  id          :string(36)    primary key
#  user_id     :string(36)    
#  location_id :string(36)    
#  created_at  :datetime      
#  updated_at  :datetime      
#

class Fave < ActiveRecord::Base
  belongs_to :user
  belongs_to :location
  #belongs_to :old_location
  
  acts_as_cached

  validates_presence_of :location_id, :user_id, :message => 'cannot be null'

  def before_create
    self.id = create_uuid
  end

  # The top urls favourited by players
  def self.top(period = 'today', page = 1)
    get_cache(period.to_s + '_' + page.to_s) do
      if period == 'all_time'
        conditions = nil
      else
        start_date, end_date = self.dates_for(period)
        conditions = ["faves.created_at BETWEEN ? AND ?", start_date, end_date]
      end
      Fave.find(:all, :select => 'id, count(faves.id) as sum, user_id, location_id, created_at', :conditions => conditions, :include => [:user, :location], :group => 'location_id', :order => 'sum DESC, created_at DESC').paginate(:page => page, :per_page => 100)

    end
  end

  # The latest urls favourited by +user+
  def self.latest_for(user, page = 1)
    get_cache("latest_for_#{user}_#{page}") do
      user.faves.find(:all, :order => 'created_at DESC').paginate(:page => page, :per_page => 100)
    end
  end
  
  def self.create_and_deposit(current_user, params)
    location = location_from(params)
    raise(Exception, "Your location is invalid.") unless location
    raise(Exception, "This type of url is not supported") if Url.unsupported_format?(location.url)
    raise(Exception, "You cannot afford any more faves") unless current_user.has_enough_datapoints?(1)
    
    with_this_data = { :location_id => location.id }

    @fave = current_user.faves.create(with_this_data)
    # Here we are going to remove the datapoint from the player, because that's...what we do.
    current_user.deduct_datapoints(1)
    
    Event.record(:user_id => current_user.id,
                 :context => 'favorite_added',
                 :recipient_id => location.id,
                 :message => "favorited <a href=\"#{location.url}\">#{location.url}</a>")
                 
  rescue NoMethodError
    raise(Exception, "Your location is invalid") unless location
  end
  
  def self.location_from(params)
    if ! params[:location_id].blank?
      location = Location.find( :first, :conditions => { :id => params[:location_id] } )
    else
      location = Location.find_or_create_by_url(params[:fave][:location], :first)
    end
    location
  end

  private
  # Returns the start and end dates for +period+
  def self.dates_for(period)
    if period == 'today' || period.nil?
      start_date = Date.today.at_beginning_of_day
      end_date = Date.tomorrow.at_beginning_of_day
    elsif period == 'yesterday'
      start_date = Date.yesterday.at_beginning_of_day
      end_date = Date.today.at_beginning_of_day
    elsif period == 'this_week'
      start_date = 0.weeks.ago.at_beginning_of_week.to_time
      end_date = 0.weeks.ago.at_end_of_week.to_time
    elsif period == 'last_week'
      start_date = 1.week.ago.at_beginning_of_week.to_time
      end_date = 1.week.ago.at_end_of_week.to_time
    end
  end
end
