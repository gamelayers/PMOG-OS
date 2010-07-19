class AcquaintancesController < ApplicationController
  before_filter :login_required
  before_filter :load_user, :except => [:add, :remove, :approve, :approve_all]
  before_filter :allow_current_user?, :only => [:show, :allies, :rivals]
  before_filter :ignore_self, :only => [:add]

  
  # GET /acquaintances/suttree
  def show
    @page_title = @user.login + "'s Contacts, Followers and Invites on "

    # validate and set defaults (for the initial page load)
    (['followers', 'invites'].include? params[:panel]) ? @panel = params[:panel] : @panel = 'contacts'
    # main is for reloading an entire tab
    (['contacts', 'allies', 'rivals', 'main'].include? params[:filter]) ? @filter = params[:filter] : @filter = 'all'

    case @panel
      when 'contacts'
        @count = @user.buddies.cached_contacts_count
        @contacts_count = @user.buddies.cached_contacts_count('acquaintance')
        @allies_count = @user.buddies.cached_contacts_count('ally')
        @rivals_count = @user.buddies.cached_contacts_count('rival')
        case @filter
          when 'main', 'all' then @contacts = @user.buddies.cached_contacts(nil, @count).paginate(:page => params[:page], :per_page => 10)
          when 'allies' then @contacts = @user.buddies.cached_contacts('ally', @allies_count).paginate(:page => params[:page], :per_page => 10)
          when 'contacts' then @contacts = @user.buddies.cached_contacts('acquaintance', @contacts_count).paginate(:page => params[:page], :per_page => 10)
          when 'rivals' then @contacts = @user.buddies.cached_contacts('rival', @rivals_count).paginate(:page => params[:page], :per_page => 10)
        end
      when 'followers'
        @count = @user.buddies.cached_followers_count
        @contacts_count = @user.buddies.cached_followers_count('acquaintance')
        @allies_count = @user.buddies.cached_followers_count('ally')
        @rivals_count = @user.buddies.cached_followers_count('rival')
        case @filter
          when 'main', 'all' then @contacts = @user.buddies.cached_followers(nil, @count).paginate(:page => params[:page], :per_page => 10)
          when 'allies' then @contacts = @user.buddies.cached_followers('ally', @contacts_count).paginate(:page => params[:page], :per_page => 10)
          when 'contacts' then @contacts = @user.buddies.cached_followers('acquaintance', @allies_count).paginate(:page => params[:page], :per_page => 10)
          when 'rivals' then @contacts = @user.buddies.cached_followers('rival', @rivals_count).paginate(:page => params[:page], :per_page => 10)
        end
    end

    respond_to do |format|
      format.html
      format.js
      format.json do
        render :json => { :contacts => current_user.buddies.contacts_for_json, :allies => current_user.buddies.allies_for_json, :rivals => current_user.buddies.rivals_for_json, :recently_active => current_user.buddies.recently_active }.to_json
      end
    end
  end
  
  def rivals
      @page_title = @user.login + "'s rivals on "

      @buddies =  @user.buddies.cached_contacts('rival').paginate(:page => params[:page], :per_page => 10)
      show_action("rivals")
      respond_to do |fmt|
        fmt.html { render :action => "show" }
        fmt.js { render :inline => render_buddies_for_share(@buddies) }
      end
  end
  
  def allies
      @page_title = @user.login + "'s allies on "
      
      @buddies =  @user.buddies.cached_contacts('ally').paginate(:page => params[:page], :per_page => 10)
      show_action("allies")
      respond_to do |fmt|
        fmt.html { render :action => "show" }
        fmt.js { render :inline => render_buddies_for_share(@buddies) }
      end
  end

  # Request a connection as an ally or rival, and automatically request them as
  # an acquaintance too
  def add
    @buddy = Buddy.find_by_login(params[:id])
    @filter = params[:filter]

    # Make the new connection and set the flash message.
    if current_user.buddies.was_connected_to? @buddy
      @buddy.update current_user, params[:type]
      flash[:notice] = "#{@buddy.login} is now your #{params[:type] == 'acquaintance' ? 'contact' : params[:type]}."
    else
      @buddy.add current_user, params[:type]
      flash[:notice] = "#{@buddy.login} is now your #{params[:type] == 'acquaintance' ? 'contact' : params[:type]}.  You made a new contact!  +#{Ping.value("Make Contact")} pings!"
    end

    # Because we're using the google search, this isn't working. At least I think that's why
    #redirect_to :back rescue redirect_to "/users/#{current_user.login}"

    respond_to do |format|
      format.js
      format.json {
        response.headers["Content-Type"] = "text/json; charset=utf-8"
        render :json => render_full_json_response(:flash => flash), :status => 201
        flash.discard
      }
      format.html {
        redirect_to user_path(params[:id])
      }
    end
  end

  # Remove a buddy, and automatically remove them as an acquaintance
  def remove
    buddy = Buddy.find_by_login(params[:id])
    buddy.remove current_user

    if params[:type] == 'rival'
      flash[:notice] = 'Rivalry cancelled!'
    elsif params[:type] == 'ally'
      flash[:notice] = 'Alliance cancelled!'
    else
      flash[:notice] = 'Contact removed!'
    end

#    # Clear the cache
#    type = params[:type]
#    [ 'ally', 'rival', 'acquaintance', '' ].each do |type|
#      current_user.expire_cache("buddies_#{current_user.id}_accepted_#{type}_")
#      current_user.expire_cache("buddies_#{current_user.id}_pending_#{type}_")
#      user_buddy.expire_cache("buddies_#{user_buddy.id}_accepted_#{type}_")
#      user_buddy.expire_cache("buddies_#{user_buddy.id}_pending_#{type}_")
#    end

    # To keep the ally/rival/acquaint buttons up to date on profile pages
    [ 'allied', 'acquainted', 'rivaled' ].each do |type|
      current_user.expire_cache("#{current_user.id}_#{type}_with_#{buddy.id}")
      buddy.expire_cache("#{buddy.id}_#{type}_with_#{current_user.id}")
    end
    
    # Because we're using the google search, this isn't working. At least I think that's why
    #redirect_to :back rescue redirect_to "/users/#{current_user.login}"
    
    redirect_to user_path(buddy.login)
  end

  # You and your acquaintances latest news feed
  def ticker
    @page_title = @user.login + '\s events on '
    @events = @user.events.cached_acquaintances_news_feed(100)
  end
  
  private
  
  def show_action(action)
    case action
    when 'pending'       then @partial = "pending"
    when 'rivals'        then @partial = "rivals"
    when 'allies'        then @partial = "allies"
    when 'acquaintances' then @partial = "acquaintances"
    end
  end
  
  def allow_current_user?
    if not show_content?(@user, current_user, "acquaintances")
      flash[:error] = "You're not allowed there!"
      redirect_to user_path(current_user.login)
    end
  end
  
  def load_user
    @user = User.find_by_login(params[:id])
  end
  
  def render_buddies_for_share(buds)
    "<script>$('share_recipients').value += '#{buds.map(&:login).join("\\n")}';</script>"
  end

  def ignore_self
    #stops people from friending themselves (only accessable thru url editing to begin with)
    if(current_user.login == params[:id])
      flash[:notice] = 'You can\'t acquaint yourself, lest the universe combust!'

      respond_to do |format|
        format.json {
          render :json => render_full_json_response(:flash => flash), :status => 201
          flash.discard
        }
        format.html {
          redirect_to user_path(current_user.login)
        }
      end
      return
    end
  end

end

