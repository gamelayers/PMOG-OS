class FacebookController < ApplicationController
  
  before_filter :require_facebook_install
  before_filter :set_user #, :except =>[ :link_fb ]
  #before_filter :require_inframe, :only => [ :index ]
  layout nil
  
  def finish_facebook_login
    redirect_to "http://apps.facebook.com/facepmog/"
  end

  # Require that we are in facebook when accessing this controller
  #  possible workaround for require_facebook_* infinite redirect
  def require_inframe
    if not in_facebook_frame?
      redirect_to "http://apps.facebook.com/facepmog/"
    end
  end
  
  # Grab the facebook id, our information about this fb user and
  # the associated PMOG user
  def set_user
    @current_fb_user_id = fbsession.session_user_id
    #Gather facebook about the given facebook user id
      #@fb_user = fbsessions.users_getInfo(
         #:uids => @current_fb_user_id,
         #:fields => ["first_name","last_name", "pic_square", "status"] )
    @fb_pmog_user = FbUser.find_by_fb_id(@current_fb_user_id)
    if ! @fb_pmog_user.blank?
      @pmog_user = User.find_by_id(@fb_pmog_user.pmog_id)
    end
  end

  # Attempts to link the facebook user with a submitted pmog user account
  def link_fb
    @pmog_user = User.authenticate(params[:login], params[:password])
    if ! @pmog_user.blank?
      @fb_user = FbUser.new(:pmog_id => @pmog_user.id, :fb_id => params[:fb_user_id])
      @fb_user.save
    end
    redirect_to :action => 'index'
  end
  
# --------------------------------------- #
# ---- Start our actions with views ----- #
# --------------------------------------- #
  def index
  end


# Using the built in rfacebook debug panel
# Its pretty swank. (not used for iframes though)
  def debug
    render_with_facebook_debug_panel
  end
end
