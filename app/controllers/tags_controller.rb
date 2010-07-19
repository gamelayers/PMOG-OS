class TagsController < ApplicationController

  # GET /tags
  def index
    respond_to do |format|
      format.html {
    	  @page_title = "Tags on "
        @tags = []
    
        @mission_tags = ["Mission", Mission.tag_counts(:order => 'count desc', :limit => 25)]
        @tags << @mission_tags
    
        @lightpost_tags = ["Lightpost", Lightpost.tag_counts(:order => 'count desc', :limit => 25)]
        @tags << @lightpost_tags
    
        @user_tags = ["User", User.tag_counts(:order => 'count desc', :limit => 25)]
        @tags << @user_tags
      }
      format.json { 
        render :json => Tag.find(:all, 
                                 :conditions => ['name LIKE :description',{:description => "#{params[:text]}%"}]).collect{|t| { t.name => t.name }}.to_json
      }
    end
  end

  # GET /tags/1
  def show
  	@page_title = "Tags like " + params[:id] + " on "
    @tag = Tag.find(params[:id])
    @tagged = get_tagged_with
  end

  private
  
  def get_tagged_with
    case params[:type]
      when "mission"   then Mission.find_tagged_with(@tag.name)
      when "lightpost" then Lightpost.find_tagged_with(@tag.name)
      when "user"      then User.find_tagged_with(@tag.name)
    end
  end

end
