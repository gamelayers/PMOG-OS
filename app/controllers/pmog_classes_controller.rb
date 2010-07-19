class PmogClassesController < ApplicationController
  before_filter :login_required
  permit 'site_admin'

  def index
    @pmog_classes = PmogClass.find(:all)
	@page_title = "Edit the Associations on "
  end

  def edit
    @pmog_class = PmogClass.find(params[:id])
	@page_title = "Edit " + @pmog_class.name.titleize + " on "
  end

  def update
    @pmog_class = PmogClass.find(params[:id])
    @pmog_class.update_attributes(params[:pmog_class])

    if @pmog_class.save
      flash[:notice] = "Class updated"
      redirect_to pmog_classes_path
    else
      flash[:notice] = "Failed to update class"
      render :action => "edit"
    end
  end
end