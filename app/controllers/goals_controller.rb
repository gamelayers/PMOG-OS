class GoalsController < ApplicationController
  # Check that the url includes a quest and create a variable for it.
  before_filter :check_quest
  # See comment on check_location below.
  before_filter :check_location, :only => [:create, :update]
  
  def index
    @goals = @quest.goals
    
    # The index has the new form on it so we're doubling the duty
    # of the index. Not sure how appropriate that is in terms of 
    # conventions but....
    @goal = Goal.new
  end
  
  def create
    @goal = @quest.goals.build(params[:goal])
    if @goal.save
      flash[:notice] = "Goal added!"
    else
      # Don't use the flash error or warning here. Just add the errors
      # to an array called flash[:errors] and the view will make this happen all pretty like.
      flash[:errors] = []
      @goal.errors.each do |e|
        flash[:errors] << "#{e[0]} #{e[1]}"
      end
    end
    redirect_to :action => 'index'
  end
  
  # The view asks for confirmation of deletion. We should probably check
  # for quest author or trustee here?
  def destroy
    Goal.destroy(params[:id])
    redirect_to :action => :index
  end
  
  def update
    @goal = Goal.find(params[:id])
    @goal.update_attributes(params[:goal])
    if @goal.save
      flash[:notice] = "Goal updated"
    else
      flash[:notice] = "Failed to update goal"
    end
  end
  
  protected
  
  def check_quest
    if params[:quest_id].nil?
      flash[:error] = "No quest included in the request"
      redirect_to "/"
    else
      @quest = Quest.find(params[:quest_id])
    end
  end
  
  # When creating / updating a goals location; i.e. the URL, the user puts in a URL (obviously)
  # But we want to store a reference to the location_id for that URL. So this is called on
  # create and update only to replace the url in the params[:goal][:location_id] with the actual
  # UUID and not the URL. Thus making it more convenient to create/update
  def check_location
    if not params[:goal][:location_id].nil? and not params[:goal][:location_id].empty?
      loc_id = Location.find_or_create_by_url(params[:goal][:location_id])
      params[:goal][:location_id] = loc_id.id
    end
  end
end
