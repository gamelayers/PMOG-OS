require 'acts_as_groupable'

ActiveRecord::Base.send(:include, ActiveRecord::Acts::Groupable)