class LeaderboardController < ApplicationController

	def index
		redirect_to :action => 'classes'
	end
	
  def classes
  	@page_title = "Browse the Class Leaderboards on "
    @pmog_classes = PmogClass.find(:all, :order => 'name').reject{|i| i.name == 'Shoats'}
    
    if params[:id].nil?
      render :action => 'classes'
    else
      @pmog_class = PmogClass.find_by_name(params[:id].pluralize.titleize)
      @leaders = DailyClasspoints.leaders_for @pmog_class.id
      @personal_stats = DailyClasspoints.total_for current_user.id, @pmog_class.id if logged_in?
      render :action => 'class_show'
    end
  end
  
  private

end
