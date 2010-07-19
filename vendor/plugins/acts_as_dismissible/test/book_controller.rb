class BookController < ActionController::Base
  
  # Override the normal location of the views for tests. #This will not work for rails 2.0 it has been changed to allow 
  # multiple view paths.
  self.template_root = File.expand_path(File.join(File.dirname(__FILE__),'/views/'))
  
  def index
  end
  
end 