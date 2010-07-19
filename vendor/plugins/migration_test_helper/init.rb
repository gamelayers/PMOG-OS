if RAILS_ENV == 'test'
  require 'migration_test_helper'
  require 'test/unit'
  Test::Unit::TestCase.class_eval do
    include MigrationTestHelper
  end
end
