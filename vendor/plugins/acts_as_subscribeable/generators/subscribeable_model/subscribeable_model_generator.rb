class SubscribeableModelGenerator < Rails::Generator::NamedBase   
  def manifest
    record do |m|
      m.template 'observer.rb', File.join('app/models', "#{file_name}_observer.rb")
      m.template 'mailer.rb', File.join('app/models', "#{file_name}_mailer.rb")
      
      m.directory File.join('app/views/', "#{file_name}_mailer")
      m.template 'email.html.erb', "app/views/#{file_name}_mailer/send_email_notification.html.erb"
    end
  end
end
