require 'dismissible'

ActionController::Base.class_eval do
  include Dismissible::Controller
end 
ActionView::Base.send :include, Dismissible::Helpers
