class HelpController < ApplicationController
  before_filter :redirect_to_guide
  
  # Just redirect to the GuideController and send a 301
  def redirect_to_guide
    redirect_to :controller => 'guide', :action => 'support', :id => params[:action], :status => 301
  end
end
