# Include hook code here
require 'acts_as_subscribeable'
ActiveRecord::Base.send(:include, RailsJitsu::Acts::Subscribeable)
