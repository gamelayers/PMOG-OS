module QueuedMissionHelper
  def queue_status(user, mission)
    queue = QueuedMission.find_by_user_id_and_mission_id(user, mission)
    if queue.nil?
       link_to image_tag("/images/missions/show_layout/save.png", :class => "mission_save_button img_no_border", :alt => "Queue This Mission"), {:controller => "queued_mission", :action => "create", :id => @mission.url_name }
    else
      link_to image_tag("/images/missions/show_layout/saved.png", :alt => "This mission is in your queue!", :class => "mission_save_button img_no_border"), {:controller => "queued_mission", :action => "delete", :id => @mission.url_name}
    end
  end
end
