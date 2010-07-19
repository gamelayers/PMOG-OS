class QueuedMissionController < ApplicationController
  before_filter :login_required
  before_filter :setup_queue, :except => :index
  
  # Returns a JSON feed of your latest Queued Missions.
  # - supports conditional GET and returns 304 as required
  def index
    respond_to do |format|
      format.json {
        queue = queued_missions_history
        #logger.info "#{current_user.login} Queued Mission Dump: " + queue.inspect
        last_modified = queue.first[:created_at] rescue 'Sun Feb 23 00:00:00 +0000 1975'.to_time
        render_not_modified_or(last_modified) do
          response.headers["Content-Type"] = "text/json; charset=utf-8"
          render :json => { :queued_missions => queue }
        end
      }
    end
  end

  def create
    @window_id = params[:window_id]
    QueuedMission.deposit(@user, @mission)
    flash[:notice] = "Saved mission for later"
    
    # Dismiss the mission
    @mission.dismiss(current_user)
    
    respond_to do |format|
      format.html { redirect_to mission_url(@mission.url_name) }
      format.js   { render :json => create_overlay(@mission, :template => 'missions/queue',  :post => 'wait_then_fade') }
      #format.json { render :json => create_overlay(@mission, :template => 'missions/queue',  :post => 'wait_then_fade') }
			format.json {
				response.headers["Content-Type"] = "text/json; charset=utf-8"
        render :json => flash.to_json, :status => 201
        flash.discard
			}
    end

  end
  
  def delete
    QueuedMission.dequeue(@user, @mission)
    flash[:notice] = "Mission removed from your queue"
    redirect_to mission_url(@mission.url_name)
  end
  
  private
  def setup_queue
    @user = current_user
    @mission = Mission.find_by_url_name(params[:id])
  end

  def queued_missions_history
    current_user.get_cache('queued_missions_list', :ttl => 1.day) do
      qms = current_user.queued_missions.uniq.delete_if { |m| m.mission.nil? }
      q = qms[0..9].collect{ |x|
        Hash['name' => x.mission.name, 'url' => host + '/missions/' + x.mission.url_name, :created_at => x.created_at]
      }
      q
    end
  end
end
