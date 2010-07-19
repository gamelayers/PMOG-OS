#
# Add useful functions that are missing

module ActiveSupport
  module CoreExtensions
    module Time
      module Calculations

 	def beginning_of_hour 
 	  change(:min => 0, :sec => 0) 
        end
 	alias :at_beginning_of_hour :beginning_of_hour 

 	def end_of_hour 
 	  change(:min => 59, :sec => 59) 
        end
 	alias :at_end_of_hour :end_of_hour

      end
    end
  end
end
