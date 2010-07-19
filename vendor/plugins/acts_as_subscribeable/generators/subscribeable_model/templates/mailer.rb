class <%= class_name.camelize %>Mailer < ActionMailer::Base
  def send_email_notification(subscriber)
    user = User.find(subscriber.id)
    @recipients  = "#{user.email}"
    @from        = "FROM_EMAIL"
    @subject     = "A <%= class_name.downcase %> you are subscribed to has been modified!"
    @sent_on     = Time.now
  end
end