# Locations are urls
class LocationsController < ApplicationController
  before_filter :login_required

  # GET /locations/UUID.json
  def show
    @location = Location.caches( :find_by_id, :with => params[:id] )
    
    respond_to do |format|
      format.json do
        response.headers["Content-Type"] = "text/json; charset=utf-8"
        render :json => { 
                          :id => @location.id, 
                          :url => @location.url, 
                          :crates => current_user.crates.find(:first, :conditions => { :location_id => @location.id }),
                          :mines => current_user.mines.find(:first, :conditions => { :location_id => @location.id }),
                          :portals => current_user.portals.find(:first, :conditions => { :location_id => @location.id }),
                          :missions => (@location.branches.collect{ |b| [b.mission.name, "http://thenethernet.com/missions/#{b.mission.url_name}"] } rescue nil),
                          :visitors_yesterday => @location.visitor_count('yesterday'),
                        }
      end
    end
  end

  # GET /locations/search.json?url=http://www.suttree.com
  def search
    if params[:id]
      @location = Location.caches( :find, :with => params[:id] )
    elsif params[:login]
      @location =Location.find_or_create_by_url(host + '/users/' + params[:login])
    else
      url = Url.extract_and_normalise_from_env(request.env[ 'QUERY_STRING' ], nil)
      @location = Location.caches( :find_or_create_by_url, :with => url )
    end
  raise ActiveRecord::RecordNotFound unless @location
    respond_to do |format|
      format.json do
        response.headers["Content-Type"] = "text/json; charset=utf-8"
        render :json => { :id => @location.id, :url => @location.url }
      end
    end
  end
end
