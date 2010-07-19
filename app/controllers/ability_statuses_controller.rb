class AbilityStatusesController < ApplicationController
  before_filter :login_required

  def toggle_dodge
    flash[:notice] = ( current_user.ability_status.toggle_dodge ? "Dodge Enabled!" : "Dodge Disabled!" )

    render :json => render_full_json_response(:flash => flash), :status => 201
  end

  def toggle_disarm
    flash[:notice] = ( current_user.ability_status.toggle_disarm ? "Dodge and Disarm Enabled!" : "Dodge and Disarm Disabled!" )

    render :json => render_full_json_response(:flash => flash), :status => 201
  end

  def toggle_vengeance
    flash[:notice] = ( current_user.ability_status.toggle_vengeance ? "Vengeance Enabled!" : "Vengeance Disabled!" )

    render :json => render_full_json_response(:flash => flash), :status => 201
  end

  def toggle_armor
    begin 
      flash[:notice] = ( current_user.ability_status.toggle_armor ? "Armor Equipped!" : "Armor Unequipped!" )
    rescue PMOG::PMOGError => e
      flash[:error] = e.message
    end

    render :json => render_full_json_response(:flash => flash), :status => 201
  end

end
