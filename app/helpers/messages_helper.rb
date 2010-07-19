module MessagesHelper

  def selected_page(action)
    return "<h3 style=\"text-align:right\">#{action == 'index' ? "Received" : link_to("Received", user_messages_path(current_user))} |
                #{action == 'system' ? "Notices" : link_to("Notices", system_user_messages_path(current_user))} |
                #{action == 'sent' ? "Sent" : link_to("Sent", sent_user_messages_path(current_user))}</h3>"
  end

end
