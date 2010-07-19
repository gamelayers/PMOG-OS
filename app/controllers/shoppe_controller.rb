class ShoppeController < ApplicationController
  before_filter :login_required

  # GET /shoppe
  def index
  	@page_title = "Shoppe on "
  	
  	@special_happenings = RssReader.get_special_happenings

    # the inventory list on the sidebar includes every tool
    @tools = Tool.cached_multi

    # the shopping list does not include every tool (some are limited by level requirement, some just cant be bought)
    # to keep things as lightweight as possible, we'll build an array of keys to not draw in the shopping panel
    # FIXME grabbing from @tools looks like shit, i must be doing this wrong -alex
    @hidden_tools = []
    @hidden_tools << 'watchdogs' if current_user.levels[:vigilante] < @tools.select{|t| t[:url_name] == 'watchdogs'}[0].level
    @hidden_tools << 'crates' if current_user.levels[:benefactor] < @tools.select{|t| t[:url_name] == 'crates'}[0].level
    @hidden_tools << 'grenades' if current_user.levels[:destroyer] < @tools.select{|t| t[:url_name] == 'grenades'}[0].level
    @hidden_tools << 'skeleton_keys'
    @hidden_tools << 'upgraded_mines'
    @hidden_tools << 'overweight_canaries'
    @hidden_tools << 'st_swatters'
    
    # we don't discount things anymore based off classes.  but maybe for paid players some day?  we'll leave this here
#    @tools.sort{ |a, b| (a.discounted?(current_user) ? 1 : 0) <=> (b.discounted?(current_user) ? 1 : 0) }
    
    respond_to do |format|
      format.html
      # the toolbar shoppe gets all the data and ignores things itself
      format.json { render :json => @tools.to_json, :status => 200 }
    end
  end

  # POST /shoppe/
  # { "order"=>{"tools"=>{"st_nicks"=>"1", "portals"=>"3", "mines"=>"2", "armor"=>"6", "lightposts"=>"4", "crates"=>"5", "watchdogs"=>"7"}},
  # for buying many items at once.
  def buy
    Shoppe.buy(current_user, params)
    flash[:notice] = "Items Purchased"
    respond_to do |format|
      format.html
      format.json do 
        render :json => render_full_json_response(:flash => flash), :status => 200
        flash.discard
      end
    end
  rescue PMOG::PMOGError => e
    shoppe_error(e.message)
  end
  
  # PUT /shoppe/1
  # For buying a single item
  def update
    tool_settings = Tool.find_by_url_name(params[:shoppe][:tool_name])
    current_user.purchase(tool_settings.url_name, params[:shoppe][:instances].to_i)
    flash[:notice] = 'You now have <b>' + current_user.inventory.send(tool_settings.url_name).to_s + '</b> ' + tool_settings.name

    respond_to do |format|
      format.html { redirect_to "/shoppe" }
    end
  rescue PMOG::PMOGError => e
    shoppe_error(e.message)
  end

  protected
  def shoppe_error(message)
    flash[:error] = message
    respond_to do |format|
      format.html { redirect_to "/shoppe" }
      format.json do 
        render :json => render_full_json_response(:flash => flash), :status => 422
        flash.discard
      end
    end
  end
end
