ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + '/../../../../config/environment')
require 'logger'
require 'fileutils'
require 'test_help'

plugin_path = RAILS_ROOT + "/vendor/plugins/migration_test_helper"

config_location = File.expand_path(plugin_path + "/test/config/database.yml")

config = YAML::load(ERB.new(IO.read(config_location)).result)
ActiveRecord::Base.logger = Logger.new(plugin_path + "/test/log/test.log")
ActiveRecord::Base.establish_connection(config['test'])

Test::Unit::TestCase.fixture_path = plugin_path + "/test/fixtures/"

$LOAD_PATH.unshift(Test::Unit::TestCase.fixture_path)

class Test::Unit::TestCase
  include FileUtils
  def plugin_path(path)
    File.expand_path(File.dirname(__FILE__) + '/../' + path)  
  end

  def load_default_schema
    ActiveRecord::Migration.suppress_messages do
      schema_file = plugin_path("/test/db/schema.rb")
      load(schema_file) if File.exist?(schema_file)
    end
  end

  def migration_test_path
    File.expand_path(RAILS_ROOT + "/test/migration")
  end

  def run_in_rails_root(command)
    cd RAILS_ROOT do
      @output = `#{command}`
    end
  end

  def check_output(string_or_regexp)
    assert_not_nil @output, "No output collected"
    case string_or_regexp
    when String
      assert_match(/#{Regexp.escape(string_or_regexp)}/, @output)
    when Regexp
      assert_match(string_or_regexp, @output)
    else
      raise "Can't check output using oddball object #{string_or_regexp.inspect}"
    end
  end
  
  def rm_migration_test_path
    rm_rf migration_test_path
  end

  def self.should(behave,&block)
    return unless running_in_foundry
    @context ||= nil
    @context_setup ||= nil
    context_string = @context.nil? ? '' : @context + ' '
    mname = "test #{context_string}should #{behave}"
    context_setup = @context_setup
    if block_given?
      define_method(mname) do
        instance_eval(&context_setup) unless context_setup.nil?
        instance_eval(&block)
      end 
    else
      puts ">>> UNIMPLEMENTED CASE: #{name.sub(/Test$/,'')} should #{behave}"
    end
  end

end
