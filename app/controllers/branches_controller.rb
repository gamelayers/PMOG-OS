class BranchesController < ApplicationController
  before_filter :login_required
  before_filter :find_mission_and_branch, :only => [:read_more]
  layout 'main', :except => [ :new, :edit ]

  def show
    redirect_to '/'
  end
  
  def read_more
    @next = @branch.next
    @previous = @branch.previous
    @show_long_description = true
    respond_to do |format|
      format.json { render :json => create_overlay('mission', :template => 'branches/show', :window_id => @mission.id, :mission_text_template => 'branches/long_description') }
      format.js { render :json => create_overlay('mission', :template => 'branches/show', :window_id => @mission.id, :mission_text_template => 'branches/long_description') }
    end
  end

  def new
    @branch = Branch.new
    @npcs = current_user.npcs
    @bird_bots = current_user.bird_bots
    @mission = Mission.find(params[:mission_id])
    @missions = Mission.find(:all, :conditions => [ 'missions.id != ?', @mission.id ], :order => 'name desc')
  end
  
  def create
    @mission = current_user.missions.find(params[:mission_id])
    @branch = @mission.branches.build(params[:branch])
    @branch.location = Location.find_or_create_by_url( Url.normalise(params[:branch][:location_id]) )

    unless params[:branch][:portal_destination].empty?
      @destination = Location.find_or_create_by_url( Url.normalise(params[:branch][:portal_destination]) )
      @branch.portal = current_user.portals.create( :location => @branch.location, :destination_id => @destination.id )
    end

    @branch.bird_bots << BirdBot.find(params[:bird_bot][:id]) unless params[:bird_bot].blank? or params[:bird_bot][:id].blank?
    @branch.npcs << Npc.find(params[:npc][:id]) unless params[:npc].blank? or params[:npc][:id].blank?
    @branch.missions << Mission.find(params[:mission][:id]) unless params[:mission].blank? or params[:mission][:id].blank?

    if @branch.valid?
      @branch.save
      current_user.tool_uses.reward :lightposts
      current_user.inventory.withdraw :lightposts
      current_user.inventory.withdraw :portals unless params[:branch][:portal_destination].empty?
      flash[:notice] = 'Branch created'
      redirect_to mission_path(@branch.mission.url_name)
    else
      flash[:notice] = 'There were problems, please try again'
      @npcs = current_user.npcs
      @bird_bots = current_user.bird_bots
      @mission = Mission.find(params[:mission_id])
      @missions = Mission.find(:all, :conditions => [ 'missions.id != ?', @mission.id ], :order => 'name desc')
      render :action => 'new'
    end
  end

  def edit
    @branch = Branch.find_with_associated(params[:id])
    @npcs = current_user.npcs
    @bird_bots = current_user.bird_bots
    @missions = Mission.find(:all, :conditions => [ 'missions.id != ?', @branch.mission.id ], :order => 'name desc')
  end

  def update
    @mission = Mission.find(params[:mission_id])
    @branch = @mission.branches.find(params[:id])

    @branch.description = params[:branch][:description]
    @branch.location = Location.find_or_create_by_url( Url.normalise(params[:branch][:location_id]) )

    unless params[:branch][:portal_destination].empty?
      @destination = Location.find_or_create_by_url( Url.normalise(params[:branch][:portal_destination]) )
      @branch.portal = current_user.portals.create( :location => @branch.location, :destination_id => @destination.id )
    end

    # Delete or edit any NPCs, Bird Bots or Missions.
    # Note that we 'clear' the assocation to keep these associations
    # single, but allow us to support multiple items, later on.
    if params[:delete_bird_bot] == 'on'
      @branch.bird_bots.clear 
    elsif params[:delete_npc] == 'on'
      @branch.npcs.clear
    elsif params[:delete_mission] == 'on'
      @branch.missions.clear
    elsif params[:delete_portal] == 'on'
      @branch.portal = nil
    elsif params[:npc] and ! params[:npc][:id].blank?
      @branch.npcs.clear
      @branch.npcs << Npc.find(params[:npc][:id])
    elsif params[:bird_bot] and ! params[:bird_bot][:id].blank?
      @branch.bird_bots.clear
      @branch.bird_bots << BirdBot.find(params[:bird_bot][:id])
    elsif params[:mission] and ! params[:mission][:id].blank?
      @branch.missions.clear
      @branch.missions << Mission.find(params[:mission][:id])
    end
    
    if @branch.valid?
      @branch.save
      current_user.inventory.withdraw :portals unless params[:branch][:portal_destination].empty?
      flash[:notice] = 'Branch updated'
      redirect_to mission_path(@branch.mission.url_name)
    else
      flash[:notice] = 'There were problems, please try again'
      render :action => 'edit'      
    end
  end

  def destroy
    @mission = Mission.find(params[:mission_id])
    Branch.destroy(params[:id])
    flash[:notice] = 'Branch deleted'
    redirect_to mission_path(@mission.url_name)
  end
  
  # Method used by the in-place editor to edit the mission description
  def set_description
    @branch = Branch.find(params[:id])
    @branch.description = params[:update_value]
    @branch.save!
    render :text => @branch.description
  end
  
  protected
  def find_mission_and_branch
    @mission = Mission.caches( :find_by_url_name, :with => params[:mission_id] )
    # Raise if the mission is not found, so that the relevant error template is rendered
    raise ActiveRecord::RecordNotFound, "Couldn't find Mission with ID=#{params[:mission_id]}" if @mission.nil?
    @branch = Branch.caches( :find, :with => params[:id])
  rescue ActiveRecord::RecordNotFound => e
    flash[:error] = "Mission could not be found. Try, reloading your browser."
    respond_to do |format|
      format.html { redirect_to('/') }
      format.json { render :json => create_error_overlay(flash[:error], :id => nil, :url => params[:url]) }
      format.js { render :json => create_error_overlay(flash[:error], :id => nil, :url => params[:url]) }
    end
  end
end
