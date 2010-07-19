class MissionSharesController < ApplicationController
  session :off
  
  def optout
    @share = MissionShare.find(params[:id])
    @shares = MissionShare.find(:all, :conditions => ['recipient = ?', @share.recipient])
    
    @shares.each {|shr| shr.optout = true}
    
    render :inline => "The email address #{@share.recipient} will no longer receive PMOG shared-mission emails."
  end
  
  def mission
    @share = MissionShare.find(params[:id])
    if @share
      cookies[:share] = params[:id] unless logged_in?
      redirect_to mission_path(@share.mission)
    else
      redirect_to '/'
    end
  end
end
