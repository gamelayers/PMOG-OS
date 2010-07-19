require 'sanitize_params'
ActionController::Base.send :include, SanitizeParams