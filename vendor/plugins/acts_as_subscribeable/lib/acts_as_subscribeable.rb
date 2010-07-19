# ActsAsSubscribeable
module RailsJitsu
  module Acts #:nodoc:
    module Subscribeable #:nodoc:

      def self.included(base)
        base.extend ClassMethods  
      end

      module ClassMethods
        def acts_as_subscribeable
          has_many :subscriptions, :as => :subscribeable
          include RailsJitsu::Acts::Subscribeable::InstanceMethods
          extend RailsJitsu::Acts::Subscribeable::SingletonMethods
        end
      end
      
      # This module contains class methods
      module SingletonMethods
        # Helper method to lookup for subscriptions for a given object.
        # This method is equivalent to obj.subscription
        def find_subscriptions_for(obj)
          # subscribeable = ActiveRecord::Base.send(:class_name_of_active_record_descendant, self).to_s
          obj_class = obj.class.to_s
         
          Subscription.find(
            :all,
            :conditions => ["subscribeable_id = ? and subscribeable_type = ?", obj.id, obj_class],
            :order => "created_at DESC"
          )
        end
        
        def user_subscribed?(obj, user)
          obj_class = obj.class.to_s
         
          Subscription.find(
            :first,
            :conditions => ["user_id = ? and subscribeable_id = ? and subscribeable_type = ?", user.id, obj.id, obj_class],
            :order => "created_at DESC"
          )
        end
                
        def add_subscription(obj, user)
          obj_class = obj.class.to_s
          
          Subscription.create(
            :user_id => user.id, :subscribeable_id => obj.id, :subscribeable_type => obj_class
          ) unless user_subscribed?(obj, user)      
        end
      
        def remove_subscription(obj, user)
          obj_class = obj.class.to_s
          
          Subscription.delete_all(
            ["user_id = ? and subscribeable_id = ? and subscribeable_type = ?", user.id, obj.id, obj_class]
          )
        end
      end
      
      # This module contains instance methods
      module InstanceMethods
      end
    end
  end
end
