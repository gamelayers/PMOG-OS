class AlliesController < ApplicationController
  before_filter :login_required
  
  # GET /allies/suttree
  def show
    @user = User.find( :first, :conditions => { :login => params[:id] }, :include => :buddies )
    @page_title = @user.login + '\'s Allies on '

    respond_to do |format|
      format.html # show.rhtml
      format.js do
        buds = @user.buddies.cached_contacts('ally')
        render :inline => 
          "<script>$('share_recipients').value += '#{buds.map(&:login).join("\\n")}';</script>"
      end
    end
  end
end
