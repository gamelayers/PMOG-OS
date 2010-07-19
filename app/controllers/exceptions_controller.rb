# An API to our logged_exceptions interface, so that the browser
# can POST new exceptions and have them recorded on the site
class ExceptionsController < ApplicationController

  # POST /exceptions.js
  def create
    
    exception = OpenStruct.new(
      :exception_class => params[:exception][:class_name],
      :controller_name => params[:exception][:controller_name],
      :action_name     => params[:exception][:action_name],
      :message         => params[:exception][:message],
      :backtrace       => params[:exception][:backtrace]
    )
    
    log_exception(exception)

    respond_to do |format|
      format.js {
        overlay = {}
        overlay[:user] = current_user_data
        add_empty_page_objects_to(overlay)
        render :json => OpenStruct.new(overlay).send(:table).to_json
      }
    end 
  end
  
  # POST /bug_report.js
  def bug_report
    flash[:notice] = "Thank you for your bug report."
    
    message_params = { :user => current_user }
    if params[:exception]
      message_params[:email] = params[:exception][:email] if params[:exception][:email]
      message_params[:dump]  = params[:exception][:dump] if params[:exception][:dump]
      message_params[:description] = params[:exception][:description] if params[:exception][:description]
      
      # Send the bug report to the bug hunters.
      Mailer.deliver_bug_report(
        :subject => "Bug report from #{current_user.login}",
        :recipients => 'gamelayers@gmail.com',
        :body => message_params
      )
    end

    respond_to do |format|
      format.json {
        render :json => create_overlay('message', :type => 'info', :text => { :content => flash[:notice] }.to_json), :status => 201
        flash.discard
      }
    end
  end
end
