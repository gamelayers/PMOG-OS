require 'acts_as_partitionable'
ActiveRecord::Base.send(:include, Suttree::Acts::Partitionable)
