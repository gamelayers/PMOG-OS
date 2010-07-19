class RatingsController < ApplicationController

  def rate
    @rateable = params[:type].constantize.find(params[:id])
    
    if params[:rating]
      
      if params[:rating].to_i > 5 or params[:rating].to_i < 1
        render :action => "invalid.rjs" and return
      else
       unless @rateable.ratings.find_by_user_id(current_user.id)
         @rateable.ratings.create( :user_id => current_user.id, :score => params[:rating] )
         current_user.reward_pings Ping.value("Rating") if params[:type] = 'Mission'
         @rateable.calculate_average_rating
         @rateable.calculate_total_ratings
       end
      end 
    end
  end
  
end
