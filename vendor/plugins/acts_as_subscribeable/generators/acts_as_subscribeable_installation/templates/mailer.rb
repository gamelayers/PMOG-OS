ActionMailer::Base.smtp_settings = {
  :address  => "mail.YOUR_DOMAIN.com",
  :domain  => 'www.YOUR_DOMAIN.com',
  :user_name  => "USER_NAME",
  :password  => "PASSWORD",
  :authentication  => :login,
  :port => 26
}