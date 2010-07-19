module Webwide #:nodoc:
  module Acts #:nodoc:
    # Overrides some basic methods for the current model so that an inactive model will not show up in normal
    # find method calls unless the is_active attribute has been set.
    # 
    # Most operations will work, but there will be some oddities.
    #
    #   class Widget < ActiveRecord::Base
    #     acts_as_activated
    #   end
    #
    #   Widget.find(:all)
    #   # SELECT * FROM widgets WHERE (widgets.is_active = 1)
    #
    #   Widget.find(:first, :conditions => ['title = ?', 'test'], :order => 'title')
    #   # SELECT * FROM widgets WHERE (widgets.is_active = 1) AND title = 'test' ORDER BY title LIMIT 1
    #
    #   Widget.find_with_inactive(:all)
    #   # SELECT * FROM widgets
    #
    #   Widget.find(:all, :with_inactive => true)
    #   # SELECT * FROM widgets
    #
    #   Widget.count
    #   # SELECT COUNT(*) FROM widgets WHERE (widgets.is_active = 1)
    #
    #   Widget.count ['title = ?', 'test']
    #   # SELECT COUNT(*) FROM widgets WHERE (widgets.is_active = 1) AND title = 'test'
    #
    #   Widget.count_with_inactive
    #   # SELECT COUNT(*) FROM widgets
    #
    module Activated
      def self.included(base) # :nodoc:
        base.extend ClassMethods
      end

      module ClassMethods
        def acts_as_activated
          unless active? # don't let AR call this twice
            class << self
              alias_method :find_with_inactive,  :find
              alias_method :calculate_with_inactive, :calculate
              #alias_method :exists_with_inactive?, :exists?
            end
          end
          include InstanceMethods
        end

        def active?
          self.included_modules.include?(InstanceMethods)
        end
      end

      module InstanceMethods #:nodoc:
        def self.included(base) # :nodoc:
          base.extend ClassMethods
        end
        
        def activate!
          @activated = true
          update_attribute(:is_active, 1)
        end
        
        def deactivate!
          update_attribute(:is_active, 0)
        end
        
        # Returns true if the item has just been activated.
        # Great for observers/notifiers
        def recently_activated?
          @activated
        end        
        
        module ClassMethods
          def find(*args)
            with_inactive_scope { find_with_inactive(*args) }
          end

          def count_with_inactive(*args)
            calculate_with_inactive(:count, *construct_count_options_from_legacy_args(*args))
          end

          def count(*args)
            with_inactive_scope { count_with_inactive(*args) }
          end

          def calculate(*args)
            with_inactive_scope { calculate_with_inactive(*args) }
          end

          def exists_with_inactive?(id)
            count_with_inactive(:conditions => ['id = ?',id] ) > 0 ? true : false
          end
          
          protected
          
            # this is taken from edge rails and not needed in the latest acts_as_activated version
            def construct_count_options_from_legacy_args(*args)
              options     = {}
              column_name = :all
              # For backwards compatibility, we need to handle both count(conditions=nil, joins=nil) or count(options={}) or count(column_name=:all, options={}).
              if args.size >= 0 && args.size <= 2
                if args.first.is_a?(Hash)
                  options     = args.first
                elsif args[1].is_a?(Hash)
                  options     = args[1]
                  column_name = args.first
                else
                  # Handle legacy paramter options: def count(conditions=nil, joins=nil)
                  options.merge!(:conditions => args[0]) if args.length > 0
                  options.merge!(:joins      => args[1]) if args.length > 1
                end
              else
                raise(ArgumentError, "Unexpected parameters passed to count(*args): expected either count(conditions=nil, joins=nil) or count(options={})")
              end
              [column_name, options]
            end

            def with_inactive_scope(&block)
              with_scope({:find => { :conditions => "#{table_name}.is_active = 1" } }, :merge, &block)
            end

        end

      end
    end
  end
end
