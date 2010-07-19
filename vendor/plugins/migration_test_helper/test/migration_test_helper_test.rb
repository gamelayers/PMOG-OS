require File.expand_path(File.dirname(__FILE__) + '/helper') 

class MigrationTestHelperTest < Test::Unit::TestCase

  def setup
    load_default_schema
    MigrationTestHelper.migration_dir = plugin_path('test/db/migrate_good')
  end

  #
  # HELPERS
  #
  def see_failure(pattern='')
    err = assert_raise(Test::Unit::AssertionFailedError) do
      yield
    end
    assert_match(/#{pattern}/mi, err.message) 
  end

  def see_no_failure
    assert_nothing_raised do
      yield
    end
  end

  def declare_columns_on_table(t)
    t.column :id,   :integer
    t.column :tail, :string, :default => 'top dog', :limit => 187
  end
  
  #
  # TESTS
  #
  def test_assert_schema_should_not_fail_if_schema_is_matched
    see_no_failure do
      assert_schema do |s|
        s.table :dogs do |t|
	  declare_columns_on_table(t)
	  t.index :tail, :name => 'index_tail_on_dogs'
        end

      end
    end
  end

  def test_assert_schema_should_fail_if_a_table_is_not_specified
    see_failure 'wrong tables in schema.*dogs' do
      assert_schema do |s|
      end
    end
  end

  def test_assert_schema_should_fail_if_a_table_is_not_found
    see_failure 'table <things> not found in schema' do
      assert_schema do |s|
        s.table :things do |t|
          t.column :id, :integer
        end
      end
    end
  end

  def test_assert_schema_should_fail_if_a_column_is_not_specified
    see_failure 'wrong columns for table.*dogs.*tail' do
      assert_schema do |s|
        s.table :dogs do |t|
          t.column :id,   :integer
        end
      end
    end
  end

  def test_assert_schema_should_fail_if_a_column_is_not_found
    see_failure 'column <legs> not found in table <dogs>' do
      assert_schema do |s|
        s.table :dogs do |t|
          t.column :id,   :integer
          t.column :tail, :string
          t.column :legs, :integer
        end
      end
    end
  end

  def test_assert_schema_should_fail_if_wrong_options_not_specified
    see_failure 'column <tail> in table <dogs> has wrong :default' do
      assert_table :dogs do |t|
        t.column :id,   :integer
        t.column :tail, :string, :default => "blah"
      end
    end
  end

  def test_assert_table_should_not_fail_if_table_is_matched
    see_no_failure do
      assert_table :dogs do |t|
        declare_columns_on_table(t)
	t.index :tail, :name => 'index_tail_on_dogs'
      end
    end
  end

  def test_assert_table_should_fail_if_a_table_is_not_found
    see_failure 'table <things> not found in schema' do
      assert_table :things do |t|
        t.column :id, :integer
      end
    end
  end

  def test_assert_table_should_fail_if_a_column_is_not_specified
    see_failure 'wrong columns for table.*dogs.*tail' do
      assert_table :dogs do |t|
        t.column :id,   :integer
      end
    end
  end

  def test_assert_table_should_fail_if_a_column_is_not_found
    see_failure 'column <legs> not found in table <dogs>' do
      assert_table :dogs do |t|
        t.column :id,   :integer
        t.column :tail, :string
        t.column :legs, :integer
      end
    end
  end

  def test_assert_table_should_fail_if_wrong_options_not_specified
    see_failure 'column <tail> in table <dogs> has wrong :default' do
      assert_table :dogs do |t|
        t.column :id,   :integer
        t.column :tail, :string, :default => "blah"
      end
    end
  end

  def test_assert_table_should_fail_if_an_index_is_not_specified
    see_failure 'wrong indexes for table: <dogs>' do
      assert_table :dogs do |t|
        declare_columns_on_table(t)
      end
    end
  end

  def test_assert_schema_should_fail_if_a_column_in_an_index_is_not_found
    see_failure 'wrong indexes for table: <dogs>' do
      assert_table :dogs do |t|
        declare_columns_on_table(t)
	t.index :legs, :name => 'index_legs_on_dogs'
      end
    end
  end

  def test_assert_schema_should_fail_if_wrong_options_on_an_index
    see_failure 'wrong indexes for table: <dogs>' do
      assert_table :dogs do |t|
        declare_columns_on_table(t)
	t.index :tail, :name => 'index_tail_on_dogs', :unique => true
      end
    end
  end

  def test_should_drop_all_tables
    assert_equal ['dogs','schema_info'].sort, ActiveRecord::Base.connection.tables.sort
    drop_all_tables
    assert_equal [], ActiveRecord::Base.connection.tables
    drop_all_tables
    assert_equal [], ActiveRecord::Base.connection.tables
  end

  def test_should_migrate_to_highest_version
    drop_all_tables
    assert_schema do |s|
    end

    migrate :version => 1

    assert_schema do |s|
      s.table :top_dogs do |t|
        t.column :id,      :integer
        t.column :name,    :string
      end
    end

    migrate :version => 2

    assert_schema do |s|
      s.table :top_dogs do |t|
        t.column :id,      :integer
        t.column :name,    :string
      end
      s.table :bottom_dogs do |t|
        t.column :id,      :integer
        t.column :name,    :string
        t.column :sick,    :boolean
      end
    end

    migrate :version => 3

    assert_schema do |s|
      s.table :top_dogs do |t|
        t.column :id,      :integer
        t.column :name,    :string
      end
      s.table :bottom_dogs do |t|
        t.column :id,      :integer
        t.column :name,    :string
        t.column :sick,    :boolean
      end
      s.table :cats do |t|
        t.column :id,      :integer
        t.column :lives,   :integer
      end
    end

    migrate :version => 0

    assert_schema do |s|
    end

    migrate

    assert_schema do |s|
      s.table :top_dogs do |t|
        t.column :id,      :integer
        t.column :name,    :string
      end
      s.table :bottom_dogs do |t|
        t.column :id,      :integer
        t.column :name,    :string
        t.column :sick,    :boolean
      end
      s.table :cats do |t|
        t.column :id,      :integer
        t.column :lives,   :integer
      end
    end
  end

  def test_should_have_default_migration_dir_set
    MigrationTestHelper.migration_dir = nil
    assert_equal File.expand_path(RAILS_ROOT + '/db/migrate'), MigrationTestHelper.migration_dir, 
      "wrong default migration dir"
    
  end

  def test_should_raise_error_if_migration_fails
    MigrationTestHelper.migration_dir = plugin_path('test/db/migrate_bad')
    drop_all_tables
    err = assert_raise RuntimeError do
      migrate
    end
    assert_match(//i, err.message)  
  end
end

