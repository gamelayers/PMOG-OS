# We've renamed the Codex to Guide, so this exists to keep old links working - duncan 16/02/09
class CodexController < GuideController
  before_filter :redirect_to_guide
  
  # Just redirect to the GuideController and send a 301
  def redirect_to_guide
    redirect_to :controller => 'guide', :action => params[:action], :id => params[:id], :status => 301
  end
end