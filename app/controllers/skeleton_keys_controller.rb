class SkeletonKeysController < ApplicationController

  def create
    flash[:notice] = SkeletonKey.create_and_deposit(current_user, params)
    render_create_response
  rescue PMOG::PMOGError => e
    flash[:error] = e.message
    render_create_response(401)
  rescue Exception => e
    log_exception e
    flash[:error] = "A server error has occured.  Please try again later."
    render_create_response(401)
  end

  protected
  def render_create_response(status = 201)
    respond_to do |format|
      format.js 
      format.json do
        response.headers["Content-Type"] = "text/json; charset=utf-8"
        render :json => render_full_json_response(:flash => flash), :status => status
        flash.discard
      end
    end
  end
end
