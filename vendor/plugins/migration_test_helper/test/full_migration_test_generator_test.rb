require File.expand_path(File.dirname(__FILE__) + '/helper') 
require File.expand_path(File.dirname(__FILE__) + '/foundry_only_helper') 

class FullMigrationTestGeneratorTest < Test::Unit::TestCase

  def setup
    return unless running_in_foundry
    rm_migration_test_path
  end

  def teardown
    return unless running_in_foundry
    rm_migration_test_path
  end


  #
  # HELPERS
  #

  def migration_test_file
    migration_test_path + "/full_migration_test.rb"
  end
  
  def run_generator
    run_in_rails_root 'script/generate full_migration_test'
  end

  #
  # TESTS
  #

  in_foundry_should "generate full migration test" do
    run_generator
    assert File.exists?(migration_test_file), "No test file made: #{migration_test_file}"
    generated_code = File.read(migration_test_file)
    source_code = File.read(plugin_path('generators/full_migration_test/templates/full_migration_test.rb'))
    assert_equal source_code, generated_code, "Wrong code generated in #{migration_test_file}"
  end

  in_foundry_should "create a test that fails in expected fashion" do
    run_generator
    cd RAILS_ROOT do
      @output = `ruby test/migration/full_migration_test.rb`
    end

    check_output '1 tests, 1 assertions, 1 failures, 0 errors'
    check_output 'implement me'
    check_output 'test_full_migration(FullMigrationTest)'
  end

end
