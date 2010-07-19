class LevelsController < ApplicationController
  before_filter :login_required
  ##before_filter :authenticate
  permit 'site_admin'

  def index
    @page_title = 'Admin : Edit Levels on '
    @levels = Level.caches(:find, :with => :all, :ttl => 1.day)
    # dunno why admins need to see this stuff, i assume debugging purposes so i'm hiding this until someone needs it
    #@level = Level.current(current_user)
    #@level_percentage = Level.percentage(current_user)
  end

  def update
    @level = Level.find(params[:id])
    @level.update_attributes(params[:level])

    Level.expire(params[:id])
    Level.expire_cache('find:all')
    Level.expire_cache('list_datapoints_required')

    if @level.valid?
      flash[:notice] = 'Level updated'
    else
      flash[:notice] = 'Error updating level'
    end
    redirect_to levels_path
  end

  def current
    @level = current_user.current_level

    respond_to do |format|
      format.js { render :json => @level.to_json }
    end
  end
end
