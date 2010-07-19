class GrenadesController < ApplicationController

  # PUT /users/login/grenades/attach.js
  def attach
    render_attach_response Grenade.create_and_attach(current_user, params)
  rescue PMOG::PMOGError => e
    render_attach_response e.message, :error, 422
  rescue Exception => e
    log_exception(e)
    render_attach_response "An internal error has occured.  Please try again.", :error, 422
  end

  protected
  def render_attach_response(message, type = :notice,  status = 201)
    flash[type] = message
    respond_to do |format|
      format.js # render the attach.rjs template.
      format.json do
        response.headers["Content-Type"] = "text/json; charset=utf-8"
        render :json => render_full_json_response(:flash => flash), :status => status
      end
    end
    flash.discard
  end
end
