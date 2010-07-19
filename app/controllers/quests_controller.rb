class QuestsController < ApplicationController
  before_filter :find_quest
  before_filter :security_check

  def index
    @quests = Quest.find(:all)
  end
  
  def show
  end
  
  def new
    @quest = Quest.new
  end
  
  def create
    @quest = Quest.new(:user => current_user,
                       :name => params[:quest][:name],
                       :description => params[:quest][:description])
    if @quest.save
      flash[:notice] = "Your quest has been created"
      redirect_to :action => "required_for", :id => @quest.to_param
    else
      render :action => "new"
    end
  end
  
  def set_requirement
    @quest.updating_level = true
    @quest.updating_association = true
    
    if @quest.update_attributes(params[:quest])
      flash[:notice] = "Quest updated"
      redirect_to quest_goals_path(@quest)
    else
      flash[:error] = "Error updating quest"
      render :action => "required_for"
    end
  end
  
  def edit
  end
  
  def update
    if !params[:quest][:level].nil?
      @quest.updating_level = true
    end
    
    if !params[:quest][:association].nil?
      @quest.updating_association = true
    end
    
    if @quest.update_attributes(params[:quest])
      flash[:notice] = "Quest updated"
      redirect_to :action => 'show', :id => @quest.to_param
    else
      render :action => "edit"
    end
  end

  def destroy
    if @quest.update_attribute(:published, false)
      flash[:notice] = "Quest disabled"
    else
      flash[:error] = "There was an error disabling this quest"
    end
    redirect_to :action => "index"
  end
  
  def publish
    if @quest.update_attribute(:published, true)
      flash[:notice] = "Quest published"
    else
      flash[:error] = "There was a problem publishing this quest"
    end
    
    redirect_to :action => "index"
  end
  
  def order
    goals = params[:goals].split(",")
    
    goals.delete_if { |e| e == "" }

    goals.each do |goal|
      Goal.update(goal, :position => goals.index(goal) + 1)
    end
    
    @goals = @quest.goals
    
    render :nothing => true
  end
  
  def required_for
    @quest
  end

  private
  def find_quest
    @quest = Quest.find(params[:id]) if params[:id]
  end
  
  def security_check
    redirect_to "/" unless site_admin?
  end
end