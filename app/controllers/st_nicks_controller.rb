class StNicksController < ApplicationController
  # PUT /users/login/st_nicks/attach.js
  # St. Nicks attach to a user and abort one effort by that user to deploy either rockets or mines. 
  def attach
    flash[:notice] = StNick.create_and_attach(current_user, params)
    render_attach_response
  rescue PMOG::PMOGError => e
    flash[:error] = e.message
    render_attach_response(401)
  rescue ActiveRecord::RecordNotFound => e
    log_exception e
    flash[:error] = "An internal server error has occured.  Please try again."
    render_attach_response(401)
  end

  protected
  def render_attach_response(status = 201)
    respond_to do |format|
      format.js # Run the rjs file
      
      # format.js do
      #   @flash = flash
      #   render :partial => 'st_nicks/attach.html.erb'
      #   flash.discard
      # end
      format.json do
        response.headers["Content-Type"] = "text/json; charset=utf-8"
        render :json => render_full_json_response(:flash => flash), :status => status
        flash.discard
      end
    end
  end
end
