class EventsSpyController < ApplicationController
  include ActionView::Helpers::TextHelper
  layout nil

  def index
    Event.get_cache('event_spy', :ttl => 5.minutes) do
      last_update = Time.parse(params[:timestamp]).utc
      #   locate the most recent event
      @event = Event.find(:first, :joins => "LEFT JOIN users ON events.user_id=users.id", :select => "events.*, users.login AS user_login", :conditions => ['events.created_at > ?', last_update.to_s(:db)])
    end
    if !@event.nil?
      render :update do |page|
        #page << "if (jQuery('##{@event.id}').length === 0) {"
        page.insert_html(:bottom, "#spy-list tbody", :partial => "single_event", :locals => { :model => @event, :display => "none" })
        #page << "jQuery('##{@event.id}').slideToggle('slow'); }"
        #page << "if (jQuery('#spy-list tbody tr').length === 7) { jQuery('#spy-list tbody tr:last-child').slideToggle('slow').remove();}"
        #page << "stripeIt();"
      end
    else
      render :nothing => true and return
    end
  end
end
