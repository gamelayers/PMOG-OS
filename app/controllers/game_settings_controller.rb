class GameSettingsController < ApplicationController
  before_filter :login_required
  ##before_filter :authenticate
  permit 'site_admin'

  def index
    @page_title = "Set the Game Settings on "
    @game_settings = GameSetting.find(:all)
  end

  # Edit a setting's value, nothing more, nothing less
  def update
    @game_setting = GameSetting.find(params[:id])
    @game_setting.value = params[:game_setting][:value]

    if @game_setting.save
      flash[:notice] = "Setting updated"
      GameSetting.expire_cache(@game_setting.key)
    else
      flash[:notice] = "Failed to update setting"
    end
    redirect_to :action => :index
  end
end
