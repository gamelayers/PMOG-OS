# ActsAsPartitionable
module Suttree
  module Acts #:nodoc:
    module Partitionable #:nodoc:

      def self.included(base)
        base.extend ClassMethods
      end
      
      # Initialise with: acts_as_partitionable :prefix => 'daily_domains'
      module ClassMethods
        def acts_as_partitionable(options={})
          before_save :set_shard_name
          before_create :set_shard_name
          before_destroy :set_shard_name
          
          # This could probably be made DRY with self.class.name instead
          @@prefix = options[:prefix]
          
          include Suttree::Acts::DateShard::InstanceMethods
          extend Suttree::Acts::DateShard::SingletonMethods
          
          set_table_name set_shard_name
        end
      end
      
      # This module contains class methods
      module SingletonMethods
        # Override find so that we can shard the daily_domains table across multiple
        # date-stamped tables, daily_domains_month_year.
        # - this is a simple way of sharding a large database table
        def self.find(*params)
          set_shard_name
          super
        end
        
        def self.set_shard_name
          self.shard_name
        end
        
        def self.shard_name
          @@prefix + Time.now.strftime('%m_%y')
        end
        
        # Copies the current daily_domains table for use in the future
        # - call this method from cron to ensure the daily_domains table 
        #   for upcoming months is created ahead of time
        def self.create_sharded_table
          current_table_name = @@prefix + Date.today.strftime('%m_%y')
          next_table_name = @@prefix + 1.month.from_now.strftime('%m_%y')
          execute( "CREATE TABLE #{next_table_name} LIKE #{current_table_name}" )
        end
      end
      
      # This module contains instance methods
      module InstanceMethods
        def set_shard_name
          self.shard_name
        end
      end
    end
  end
end
