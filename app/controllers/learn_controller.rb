class LearnController < ApplicationController
  before_filter :redirect_home
  before_filter :login_required

  def redirect_home
    redirect_to '/', :status => 301 and return
  end
  
  def index
    @page_title= 'Learn to Play '
  end
  
  def mines
	  @page_title= 'Learn Mines on '
  end

  def crates
	  @page_title= 'Learn Crates on '
  end

  def portals
	  @page_title= 'Learn Portals on '
  end

  def armor
	  @page_title= 'Learn Armor on '
  end

  def st_nicks
	  @page_title= 'Learn St. Nicks on '
  end

  def lightposts
	  @page_title= 'Learn Lightposts on '
  end

  def missions
	  @page_title= 'Learn Missions on '
  end
  
  def remember
  	@page_title= 'Remember this about '
  end
end
