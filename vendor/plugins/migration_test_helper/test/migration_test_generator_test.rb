require File.expand_path(File.dirname(__FILE__) + '/helper') 
require File.expand_path(File.dirname(__FILE__) + '/foundry_only_helper') 

class MigrationTestGeneratorTest < Test::Unit::TestCase

  def setup
    return unless running_in_foundry
    rm_migration_test_path
    rm_migrations   
  end

  def teardown
    return unless running_in_foundry
    rm_migration_test_path
    rm_migrations   
  end


  #
  # HELPERS
  #

  def generate_migration(expected_version, name)
    run_in_rails_root "script/generate migration #{name}"
    migration_file = "db/migrate/#{expected_version}_#{name}.rb"
    assert File.exists?(migration_file), "Migration not there: #{migration_file}"
  end

  def generate_migration_test(version)
    run_in_rails_root "script/generate migration_test #{version}"

  end

  def rm_migrations
    rm Dir["db/migrate/*.rb"]
  end
  
  #
  # TESTS
  #
  
  in_foundry_should "generate a migration test for schema 1" do
    generate_migration '001', 'create_the_dogs_table'

    generate_migration_test '1'

    migration_test_file = "test/migration/001_create_the_dogs_table_test.rb"
    assert File.exists?(migration_test_file), "Migration test not there: #{migration_test_file}"

    run_in_rails_root "ruby #{migration_test_file}"
    check_output 'test_migration_should_create_the_dogs_table(CreateTheDogsTableTest)'
    check_output '1) Failure:'
    check_output 'TODO: setup test data.'
    check_output '1 tests, 1 assertions, 1 failures, 0 errors'
  end

  in_foundry_should "generate a migration test for schema 2" do
    generate_migration '001', 'create_the_dogs_table'
    generate_migration '002', 'transfer_cats_data'
    generate_migration_test '002'
    migration_test_file = "test/migration/002_transfer_cats_data_test.rb"
    assert File.exists?(migration_test_file), "Migration test not there: #{migration_test_file}"

    run_in_rails_root "ruby #{migration_test_file}"
    check_output 'test_migration_should_transfer_cats_data(TransferCatsDataTest)'
    check_output '1) Failure:'
    check_output 'TODO: setup test data.'
    check_output '1 tests, 1 assertions, 1 failures, 0 errors'
  end

  in_foundry_should "fail if no schema version is provided" do
    generate_migration '001', 'create_the_dogs_table'
    generate_migration_test ''
    check_output 'Usage: script/generate migration_test MigrationTestName [options]'
  end

  in_foundry_should "fail if bad schema version is provided" do
    generate_migration '001', 'create_the_dogs_table'
    generate_migration_test 'oops'
    check_output(/Invalid schema version 'oops'/i)
  end

  in_foundry_should "fail if schema version does not correspond to existing migration" do
    generate_migration '001', 'create_the_dogs_table'
    generate_migration_test '2'
    check_output "No migration found for schema version 002"
  end

end
