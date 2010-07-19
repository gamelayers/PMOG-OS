module MissionsHelper
  
  # Render an image depending on whether or not a step in the generator is complete
  # accept is the boolean, true = show link and accept icon, false = show text, no link and reject icon
  # text is the text to display in the link or as the text when there is no link ala false in the boolean
  # action is the action to link to.
  def progress_for(valid, is_active_view, step, action = nil)
    step_object = nil
    
    if action.nil? and not is_active_view
      return content_tag(:div, "&nbsp;", :class => "#{step + "_incomplete_disabled"}")
    elsif action.nil? and is_active_view
      return content_tag(:div, "&nbsp;", :class => "#{step + "_incomplete_active"}")
    end
    
    if valid
      if is_active_view
        step_object = content_tag(:div, "&nbsp;", :class => "#{step + "_complete_active"}")
      else
        step_object = link_to("&nbsp;", action, :class => "#{step + "_complete"}")
      end
    else
      if is_active_view
        step_object = content_tag(:div, "&nbsp;", :class => "#{step + "_incomplete_active"}")
      else
        step_object = link_to("&nbsp;", action, :class => "#{step + "_incomplete_enabled"}")
      end
    end
    
    return step_object
  end
  
  def queue_button(view, mission)
     if not logged_in?
       case view
         when 'index' then return content_tag(:span, link_to_remote("Queue", :url => "#", :html => {:class => "button_queue_locked", :title => "You must be logged in to queue this mission!"}))
       end
     else
       if ! mission.users.include? current_user
         exists = current_user.missions_queued.include? mission
         
         if exists
           url = dequeue_user_mission_path(:user_id => current_user.id, :id => mission.id, :view => view)
           method = :delete
         else
           url = queue_user_mission_path(:user_id => current_user.id, :id => mission.id, :view => view)
           method = :put
         end

         case view
           when 'index' then return content_tag(:span, link_to_remote("#{"un" if exists}Queue", :url => url, :method => method, :html => {:class => "missions_index_#{"un" if exists}queue"}), :id => "queue_button_#{mission.id}")
           when 'show'  then return content_tag(:span, link_to_remote("#{"un" if exists}Queue", :url => url, :method => method, :html => {:class => "mission_#{"un" if exists}queue"}), :id => "queue_button_#{mission.id}")
         end
       end
     end
   end
   
  def take_button(mission)
    if not logged_in?
      return content_tag(:span, link_to_remote("Take", :url => "#", :html => {:class => "button_take_locked", :title => "You must be logged in to take this mission!"}))
    else
      if mission.users.include? current_user
        cls = "missions_index_taken"
      else
        cls = "missions_index_take"
      end
      link_to("Take", take_mission_path(mission.url_name), :class => cls)
    end
  end
  
  def favorite_button(view, mission)
     if logged_in?

       if mission.users.include? current_user
         exists = current_user.all_favorites.include? mission
         
         if exists
           url = unfavorite_user_mission_path(:user_id => current_user.id, :id => mission.id, :view => view)
           method = :delete
         else
           url = favorite_user_mission_path(:user_id => current_user.id, :id => mission.id, :view => view)
           method = :put
         end

         case view
           when 'index' then return content_tag(:span, link_to_remote("#{"un" if exists}Favorite", :url => url, :method => method, :html => {:class => "missions_index_#{"un" if exists}favorite"}), :id => "favorite_button_#{mission.id}")
           when 'show'  then return content_tag(:span, link_to_remote("#{"un" if exists}Favorite", :url => url, :method => method, :html => {:class => "mission_#{"un" if exists}favorite"}), :id => "favorite_button_#{mission.id}")
         end
       end
     end
   end
  
  # Because we're using one template to show all missions on the index, we have a problem with drafts linking directly to the mission
  # and not to the drafts themselves. So we'll have this helper to determine what to use: a link to the mission/show or to the mission/edit
  def link_to_mission(mission, text=nil)
    if text.nil?
      text = mission.name
    end
    
    if mission.is_active?
			link_to text, mission_path(mission.url_name)
    else
			link_to text, edit_mission_path(mission.url_name)
		end
  end
  
  
  def sort_class_helper(param)
    result = 'class="sortup"' if params[:sort] == param
    result = 'class="sortdown"' if params[:sort] == param + "_reverse"
    return result
  end
  
  def sort_link_helper(text, param, action)
    key = param
    key += '_reverse' if params[:sort] == param
    options = {
        :url => {:action => action, :params => params.merge({:sort => key, :page => nil})}, :method => :get,
                 :loading => "jQuery('#loading').show();",:complete => "jQuery('#loading').hide();"
    }
    html_options = {
      :title => "Sort by #{param}",
      :href => url_for(:action => action, :params => params.merge({:sort => key, :page => nil}))
    }
    link_to_remote(text, options, html_options)
  end
  
  def fetch_buddies_button(text, urltop)
    "<input class=\"wee\" type=\"button\" id=\"share_allies\" value=\"#{text}\"" +
    "  onclick=\"new Ajax.Updater('share_recipients', " +
    "  '/#{urltop}/#{current_user.login}?authenticity_token=#{form_authenticity_token}', " +
  "  {method: 'get', evalScripts: true});return false;\" />"
  end
end
