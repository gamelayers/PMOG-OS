plugin_test_dir = File.dirname(__FILE__)
require File.join(plugin_test_dir, '/test_helper')

# Load the Rails environment
require File.join(plugin_test_dir, '../../../../config/environment')
require 'active_record/base'
require 'test/unit'

# Load up out database & create our logger
databases = YAML::load(File.join(plugin_test_dir, '/database.yml'))
ActiveRecord::Base.logger = Logger.new(plugin_test_dir + "/debug.log")

# Connect to our plugin test database
ActiveRecord::Base.establish_connection(databases[ENV['DB'] || 'sqlite3'])

# Load the test schema into the database
load(File.join(plugin_test_dir, 'schema.rb'))