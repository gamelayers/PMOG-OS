class TopicMailer < ActionMailer::Base
  def send_email_notification(subscriber, topic)
    user = User.find(subscriber.id)
    last_poster = topic.recent_posts.first.user.login
    recipients     user.email
    from           'noreply@thenethernet.com'
    subject        "The Nethernet Forum topic \"#{topic.title}\" has been updated"
    body           :topic => topic, :user => user, :last_poster => last_poster
    @sent_on     = Time.now
  end
end