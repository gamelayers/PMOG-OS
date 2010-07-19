module TopicsHelper
  
  def show_subscription_button(topic, user)
    if Topic.user_subscribed?(topic, user)
      return link_to_remote("&nbsp;", :url => unsubscribe_forum_topic_path(:forum_id => @topic.forum.url_name, :id => @topic.url_name), :method => :put, :html => {:class => "forum_thread_unsubscribe"})
    else
      return link_to_remote("&nbsp;", :url => subscribe_forum_topic_path(:forum_id => @topic.forum.url_name, :id => @topic.url_name), :method => :put, :html => {:class => "forum_thread_subscribe"})
    end
  end
  
end
