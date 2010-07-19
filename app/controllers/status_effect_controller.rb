class StatusEffectController < ApplicationController

  def impede
    flash[:notice] = StatusEffect.impede current_user, params[:id]

    respond_to do |format|
      format.json do
        render :json => render_full_json_response(:flash => flash), :status => 200
        flash.discard
      end
    end

  rescue PMOG::PMOGError => e
    render_json_error e.message, 422
  rescue Exception => e
    log_exception e
    render_json_error "A server error has occured.  Please try again later."
  end

  def overclock
    flash[:notice] = StatusEffect.overclock current_user, params[:id]

    respond_to do |format|
      format.json do
        render :json => render_full_json_response(:flash => flash), :status => 200
        flash.discard
      end
    end

  rescue PMOG::PMOGError => e
    render_json_error e.message, 422
  rescue Exception => e
    log_exception e
    render_json_error "A server error has occured.  Please try again later."
  end

  def render_json_error(msg, status = 422)
    flash[:error] = msg
    respond_to do |format|
      format.json do
        render :json => render_full_json_response(:flash => flash), :status => status
      end
    end
    flash.discard
  end

end
