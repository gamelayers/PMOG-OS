class <%= class_name.underscore.camelize %>Observer < ActiveRecord::Observer
  def after_update(<%= class_name.underscore.downcase %>)
    <%= class_name.underscore.downcase %>.subscriptions.each do |subscription|
      <%= class_name.camelize %>Mailer.deliver_send_email_notification(subscription.user)
    end
  end
end