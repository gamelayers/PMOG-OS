# From http://snippets.dzone.com/posts/show/1338
class Mailer < ActionMailer::Base

  helper ActionView::Helpers::UrlHelper

  # Create placeholders for whichever e-mails you need to deal with.
  # Override mail elements where necessary
  def generic_mailer(options)
    @recipients = options[:recipients]
    @from = options[:from] || 'noreply@thenethernet.com'
    @cc = options[:cc] || ''
    @bcc = options[:bcc] || ''
    @subject = options[:subject] || 'The Nethernet Email'
    @body = options[:body] || {}
    @headers = options[:headers] || {}
    @charset = options[:charset] || 'utf-8'
    @reply_to = options[:reply_to] || ''
  end

  def new_user(options)
    self.generic_mailer(options)
  end
  
  def bug_report(options)
    self.generic_mailer(options)
  end
  
  def password_reset(options)
    self.generic_mailer(options)
  end
  
  def beta_key(options)
    self.generic_mailer(options)
  end
  
  def friend_request(options)
    self.generic_mailer(options)
  end
  
  def acquaintance_request(options)
    self.generic_mailer(options)
  end

  def ally_request(options)
    self.generic_mailer(options)
  end
  
  def rival_request(options)
    self.generic_mailer(options)
  end
  
  def confirm_unsubscribe(options)
    self.generic_mailer(options)
  end
  
  def shared_mission(options)
    self.generic_mailer(options)
  end

  def contact(options)
    self.generic_mailer(options)
  end

  def top_domains(options)
    self.generic_mailer(options)
  end
  
  def email_invite(options)
    self.generic_mailer(options)
  end
end
