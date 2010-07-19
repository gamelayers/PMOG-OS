class AbilitiesController < ApplicationController
  before_filter :login_required
  permit 'site_admin'
  
  def index
    @abilities = Ability.find(:all)
  	@page_title = "Edit Abilities on "
  end
  
  def edit
    @ability = Ability.find(params[:id])
		@page_title = "Edit " + @ability.name.titleize + " on "
  end
  
  def update
    @ability = Ability.find(params[:id])
    @ability.update_attributes(params[:ability])
    
    if @ability.save
      @ability.expire_cache(@ability.url_name.to_sym)
      flash[:notice] = "Ability updated"
      redirect_to abilities_path
    else
      flash[:notice] = "Failed to update ability"
      render :action => "edit"
    end
  end
end
