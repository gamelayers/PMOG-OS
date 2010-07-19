$:.unshift(File.dirname(__FILE__))
$:.unshift(File.dirname(__FILE__) + "/../lib")

ENV["RAILS_ENV"] = "test"

require 'action_controller'
require 'action_controller/test_process'

# Show backtraces for deprecated behavior for quicker cleanup.
ActiveSupport::Deprecation.debug = true
ActionController::Base.logger = Logger.new("log/debug.log")
ActionController::Base.ignore_missing_templates = true

begin
  require "active_record" unless Object.const_defined?(:ActiveRecord)
  require "active_record/fixtures" unless Object.const_defined?(:Fixtures)
rescue LoadError => e
  fail "\nFailed to load activerecord: #{e}"
end

ActiveRecord::Base.configurations = {
  'mysql' => {
    :adapter  => "mysql",
    :username => "root",
    :encoding => "utf8",
    :database => "test"
  }
}

ActiveRecord::Base.establish_connection 'mysql'
