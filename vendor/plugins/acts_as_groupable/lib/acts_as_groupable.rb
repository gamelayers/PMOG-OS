module ActiveRecord
  module Acts
    module Groupable
      def self.included(base)
        base.extend(ClassMethods)
      end
      
      module ClassMethods
        def acts_as_groupable(options = {})
          belongs_to :group, :polymorphic => true
          
          extend ActiveRecord::Acts::Groupable::SingletonMethods          
          include ActiveRecord::Acts::Groupable::InstanceMethods
        end
      end
      
      module SingletonMethods
        # A convenience method to pass the group object in and get all
        # the groupable objects associated with it. 
        def find_by_group(group)
          find_all_by_group_id(group.id)
        end
        
        def group_name(groupable)
          Group.find_by_id(groupable.group_id).name
        end
      end
      
      module InstanceMethods
        # Get all the other groupable objects in the same group as
        # this object
        def find_all_in_group
          # Find all objects of the same kind with the same grouping
          find_all_by_group_id(self.group_id)
        end
      end
    end
  end
end
