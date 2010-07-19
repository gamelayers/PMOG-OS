class RivalsController < ApplicationController
  before_filter :login_required
    
  # GET /rivals/suttree
  def show
    @user = User.find( :first, :conditions => { :login => params[:id] }, :include => :buddies )
    @page_title = @user.login + "'s Rivals on "

    respond_to do |format|
      format.html # show.rhtml
      format.js do
        buds = @user.buddies.cached_contacts('rival')
        render :inline => 
          "<script>$('share_recipients').value += '#{buds.map(&:login).join("\\n")}';</script>"
      end
    end
  end
end
