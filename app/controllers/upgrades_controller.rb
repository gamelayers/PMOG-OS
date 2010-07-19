class UpgradesController < ApplicationController
  before_filter :login_required
  #before_filter :authenticate
  permit 'site_admin'
  
  def index
    @upgrades = Upgrade.find(:all)
  	@page_title = "Edit Upgrades on "
  end
  
  def edit
    @upgrade = Upgrade.find(params[:id])
		@page_title = "Edit " + @upgrade.name.titleize + " on "
  end
  
  def update
    @upgrade = Upgrade.find(params[:id])
    @upgrade.update_attributes(params[:upgrade])
    
    if @upgrade.save
      @upgrade.expire_cache(@upgrade.url_name.to_sym)
      flash[:notice] = "Upgrade updated"
      redirect_to upgrades_path
    else
      flash[:notice] = "Failed to update upgrade"
      render :action => "edit"
    end
  end
end
