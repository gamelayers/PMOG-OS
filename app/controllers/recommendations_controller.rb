class RecommendationsController < ApplicationController

  # Speed up recommendations using inline C
  # See http://blog.chrislowis.cookies.uk/2008/11/24/ruby-gsl-pearson.html
  
  before_filter :login_required
  #before_filter :authenticate
  before_filter :load_pool_and_recommendations, :except => :index
  permit 'site_admin'

  def users
  	@page_title = "Users recommended by "
    @users = @recommendation.users_for(current_user.login)
  end

  def locations
  	@page_title = "Sites recommended by "
    @locations = @recommendation.locations_for(current_user.login)
  end

  def find_a_friend
    @users = User.find( :all, :conditions => [ "last_login_at > ?", 1.week.ago ], :order => 'last_login_at DESC', :limit => 10 )
    @recommendation.set_domains_for(@users)
    @users = @recommendation.users_for(current_user.login)
  end

  protected
  # Recommend based on the trustees habits
  def load_trustees_and_recommendations
    @trustees = Role.find_by_name('site_admin').users
    @recommendation = Recommendation.new
    @recommendation.set_domains_for(@trustees)
  end

  # Recommend based on your allies, rivals and auto acquaintances
  def load_pool_and_recommendations
    @recommendation = Recommendation.new
    @recommendation.set_domains_for(current_user.buddies.pool)
  end
end
