class ToolsController < ApplicationController
  before_filter :login_required
  #before_filter :authenticate
  permit 'site_admin'
  
  def index
    @tools = Tool.find(:all)
  	@page_title = "Edit Tools on "
  end
  
  def edit
    @tool = Tool.find(params[:id])
		@page_title = "Edit " + @tool.name.titleize + " on "
  end
  
  def update
    @tool = Tool.find(params[:id])
    @tool.update_attributes(params[:tool])

    # Clear the tool cache whether it saves or not, to keep things fresh - duncan 14/01/08
    Tool.expire_cache(params[:tool].to_s)
    Tool.expire_cache(:multi)
    
    if @tool.save
      flash[:notice] = "Tool updated"
      redirect_to tools_path
    else
      flash[:notice] = "Failed to update tool"
      render :action => "edit"
    end
  end
end
