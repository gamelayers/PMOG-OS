class ArmorsController < ApplicationController
  before_filter :login_required

  # PUT /users/login/armor/equip.js
  # - Deprecated - use ability status in future
  def equip
    render_failure('This API endpoint is deprecated.')
  end

  # PUT /users/login/armor/unequip.js
  # - Deprecated - use ability status in future
  def unequip
    render_failure('This API endpoint is deprecated.')
  end
  
  protected
  def render_failure(msg)
    flash[:error] = msg
    render :json => render_full_json_response(:flash => flash), :status => 422
  end
end
