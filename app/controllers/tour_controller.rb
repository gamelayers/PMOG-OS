class TourController < ApplicationController
  
  def index
    img_loc = "/images/new_player/tour/"

    @images =  [img_loc + "1_toolbar.png", 
                img_loc + "2_shoppe.png", 
                img_loc + "3_mines.png", 
                img_loc + "4_crates.png", 
                img_loc + "5_missions.png", 
                img_loc + "6_profile.png"
              ]
    @heading_text = ["Earn Datapoints for Surfing the Web (2 DP per top-level URL).",
                     "Spend Datapoints at the Shoppe to buy a wide range of Tools.",
                     "Prank your friends across the web using Mines.",
                     "Leave gifts on web sites using Crates to hold Tools or Datapoints.",
                     "Generate or Take Missions Online!",
                     "Develop a rich user profile passively, just by surfing the web."
                    ]
              
    @page_title = "Take a Tour of "
    if params[:page].nil?
      params[:page] = 1
    end
    
    page = params[:page].to_i  
      
    @image = @images[(page - 1)] 
    
    respond_to do |format|
      format.html
      format.js {
        render :update do |page|
          page.replace_html 'tour_image_container', image_tag(@image, :alt => "Missions", :class => "tour_image")
          if params[:page].to_i < @images.length
            page.replace_html "next_arrow", link_to_remote("", :url => {:action => "index", :page => params[:page].to_i + 1}, :html => {:class => "tour_next"})
          else
            page.replace_html "next_arrow", ""
          end
          if params[:page].to_i > 1
            page.replace_html "prev_arrow", link_to_remote("", :url => {:action => "index", :page => params[:page].to_i - 1}, :html => {:class => "tour_prev"})
          else 
            page.replace_html "prev_arrow", "&nbsp;&nbsp;"
          end
          page.replace_html "heading_text", @heading_text[params[:page].to_i - 1]
        end
      }
    end
  end
end
