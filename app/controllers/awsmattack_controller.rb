class AwsmattackController < ApplicationController
  def index
    unless read_fragment("awsmattack_#{params.to_s}")
      @page_title = "The Top Awsm-Attacks on "

      @top_awsm_this_week = Awsmattack.top('awsm', 'this_week')
      @top_attack_this_week = Awsmattack.top('attack', 'this_week')
      @most_recent_awsm = Awsmattack.recent('awsm')
      @most_recent_attack = Awsmattack.recent('attack')

      respond_to do |format|
        format.html { render :action => :index } # index.html.erb
        format.json do
          response.headers["Content-Type"] = "text/json; charset=utf-8"
          render :json => {
            :top_awsm_this_week => @top_awsm_this_week.collect{ |a| { :id => a.id, :location_id => a.location_id, :count => a.count } },
            :top_attack_this_week => @top_attack_this_week.collect{ |a| { :id => a.id, :location_id => a.location_id, :count => a.count } }, 
            :most_recent_awsm => @most_recent_awsm.collect{ |a| { :id => a.id, :location_id => a.location_id, :created_at => a.created_at } }, 
            :most_recent_attack => @most_recent_attack.collect{ |a| { :id => a.id, :location_id => a.location_id, :created_at => a.created_at } }, 
          }.to_json
        end
      end
    end
  end
end
