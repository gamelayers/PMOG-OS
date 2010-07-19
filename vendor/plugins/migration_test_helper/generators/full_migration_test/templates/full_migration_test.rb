require File.expand_path(File.dirname(__FILE__) + '/../test_helper') 

#
# This excercises the full set of migrations for your Rails app.
# It proves:
#   - After full migration, the database is in the expected state, including:
#     - All table structure
#     - Default data (if any)
#   - Full downward (version 0) migration functions correctly.
#
# YOU NEED TO:
#   - Update "see_full_schema"
#   - Update "see_data"
# 
class FullMigrationTest < ActionController::IntegrationTest

  # 
  # Transactional fixtures can, on occasion, cause migration tests to hang.
  # Applying this setting here will turn transactional fixtures off for THIS
  # SUITE ONLY
  #
  # self.use_transactional_fixtures = false

  def conn
    ActiveRecord::Base.connection
  end

  def see_empty_schema
    assert_schema do |s|
      # is nothing 
    end
  end

  #
  # Structure and Content assertions
  #

  # Fully assert db structure after full migration
  def see_full_schema
    # TODO: add assertions here to verify your schema was built
    flunk "implement me"
    
    #
    # Something like this can be used to see the entire schema
    # is as expeted.
    #
    # assert_schema do |s|
    #   s.table :cat_tails do |t|
    #     t.column :id,    :integer
    #     t.column :name,  :string
    #   end
    #
    #   s.table :dogs do |t|
    #     t.column :id,    :integer
    #     t.column :name,  :string
    #   end
    # end

    #
    # Alternatively individual tables can be checked.
    #
    # assert_table :cats_tails do |s|
    #   t.column :id,    :integer
    #   t.column :name,  :string
    # end
  end

  # Make sure data you expect your migrations to load are in there:
  def see_default_data
    # TODO: add assertions here to verify any default data was loaded
  end

  #
  # TESTS
  #

  def test_full_migration
    drop_all_tables
    
    see_empty_schema

    migrate

    see_full_schema

    see_default_data
  end

end
