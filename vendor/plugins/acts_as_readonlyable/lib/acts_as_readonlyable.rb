# Copyright (c) 2007 Revolution Health Group LLC. All rights reserved.

module ActiveRecord; module Acts; end; end 

module ActiveRecord::Acts::ActsAsReadonlyable
  
  def self.included(base)
    base.extend(ClassMethods)  
  end
  
  module ClassMethods
    
    def acts_as_readonlyable(*readonly_dbs)
      readonly_dbs = readonly_dbs.flatten.collect(&:to_s)
      readonly_models = readonly_classes(readonly_dbs)
      if readonly_models.empty?
        logger.warn("Read only mode is not activated for #{ self }")
      else 
        define_readonly_model_method(readonly_models)
        self.extend(FinderClassOverrides)
      end
      self.send(:include, FinderInstanceOverrides)
    end
    
  private
    
    def readonly_classes(dbs)
      dbs.inject([]) do |classes, db|
        if configurations[RAILS_ENV][db]
          define_readonly_class(db) unless ActiveRecord.const_defined?(readonly_class_name(db))
          classes << ActiveRecord.const_get(readonly_class_name(db))
        else
          logger.warn("No db config entry defined for #{ db }")
        end
        classes
      end
    end 
       
    def readonly_class_name(db)
      "Generated#{ db.camelize }"
    end
    
    def define_readonly_class(db)
      ActiveRecord.module_eval %Q!
        class #{ readonly_class_name(db) } < Base
          self.abstract_class = true
          establish_connection configurations[RAILS_ENV]['#{ db }']
        end
      !
    end
    
    def define_readonly_model_method(readonly_models)
      (class << self; self; end).class_eval do
        define_method(:readonly_model) { readonly_models[rand(readonly_models.size)] }
      end
    end
    
    module FinderClassOverrides
      
      def find_every(options)
        run_on_db(options) { super }
      end
      
      def find_by_sql(sql, options = nil) 
        
        # Called through construct_finder_sql
        if sql.is_a?(Hash)
          options = sql
          sql = sql[:sql]
        end
        
        run_on_db(options) { super(sql) }
        
      end
      
      def count_by_sql(sql, options = nil)
        run_on_db(options) { super(sql) }
      end
      
      def construct_finder_sql(options)
        options.merge(:sql => super)
        super
      end
      
      def set_readonly_option!(options) #:nodoc:
        # Inherit :readonly from finder scope if set.  Otherwise,
        # if :joins is not blank then :readonly defaults to true.
        unless options.has_key?(:readonly)
          if scoped?(:find, :readonly)
            options[:readonly] = true if scope(:find, :readonly)
          elsif !options[:joins].blank? && !options[:select]
            options[:readonly] = true
          end
        end
      end
      
      def calculate(operation, column_name, options = {})
        run_on_db(options) do
          options.delete(:readonly)
          super
        end
      end
      
      
      private
      
      def run_on_db(options)
        if ((Thread.current['open_transactions'] || 0) == 0) and with_readonly?(options)
          run_on_readonly_db { yield }
        else
          yield
        end
      end

      def with_readonly?(options)
        (! options.is_a?(Hash)) || (! options.key?(:readonly)) || options[:readonly]
      end
      
      def run_on_readonly_db
        klass_conn = connection
        begin
          self.connection = readonly_model.connection
          self.clear_active_connection_name
          yield
        ensure
          self.connection = klass_conn
          self.clear_active_connection_name
        end
        
      end
      
    end
    
    module FinderInstanceOverrides
      
      # backport from 1.2.3 for 1.1.6 + disable readonly by default for reload - replication lag
      def reload(options = {})
        options[:readonly] = false unless options.has_key?(:readonly)
        clear_aggregation_cache
        clear_association_cache
        @attributes.update(self.class.find(self.id, options).instance_variable_get('@attributes'))
        self
      end
      
    end
    
  end
  
end

ActiveRecord::Base.send(:include, ActiveRecord::Acts::ActsAsReadonlyable)
