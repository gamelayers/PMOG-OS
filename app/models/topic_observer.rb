class TopicObserver < ActiveRecord::Observer
  def after_update(topic)
    topic.subscriptions.each do |subscription|
      TopicMailer.deliver_send_email_notification(subscription.user, subscription.subscribeable)
    end
  end
end