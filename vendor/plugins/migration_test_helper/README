= MigrationTestHelper

MigrationTestHelper provides methods which let you assert the current state of the schema and run your migrations against the _test_ database.

== Install

  ./script/plugin install svn://rubyforge.org/var/svn/migrationtest/tags/migration_test_helper

OR

  gem install migration_test_helper


If you're using it outside of a Rails environment (for whatever reason) include the MigrationTestHelper module in your tests:

  require 'test/unit'
  require 'migration_test_helper'

  class MyTest < Test::Unit::TestCase
    include MigrationTestHelper
    
    def test_something
      ...
    end
  end

== Use

*assert_schema*: verifies the schema of the database exactly matches the one specified.

  def test_the_schema
    assert_schema do |s|
      s.table :books do |t|
        t.column :id,     :integer
        t.column :title,  :string, :limit => 5
        t.column :author, :string
      end

      s.table :reviews do |t|
        t.column :id,      :integer
        t.column :book_id, :integer
        t.column :body,    :text
        t.column :rating,  :integer, :default => 0
        t.index  :book_id, :name => 'index_book_id_on_reviews'
      end
    end
  end

This would verify there are only two tables defined in the test database: _books_ and _reviews_ (schema_info is ignored).  It will also verify that the _book_ table has the three columns, _id_, _title_ and _author_, each with their respective types. Indexes are verified too.


*assert_table*: verify a table is found exactly as specified:

  assert_table :books do |t|
    t.column :id,     :integer
    t.column :title,  :string, :limit => 5
    t.column :author, :string
    t.index  :author, :name => 'index_author_on_books'
  end


*drop_all_tables*: does just what it says to your _test_ database.


*migrate*: executes the migrations against the test database using the same mechanism as rake db:migrate.

  def test_the_migrations
    migrate
    migrate :version => 0
    migrate :version => 10
    migrate
  end
  

This would do the same thing as running the following rake commands, but within a test case:

  rake db:migrate
  rake db:migrate VERSION=0
  rake db:migrate VERSION=10
  rake db:migrate
  

By combining the two helpers you can write a test that shows you can run all your migrations and get the final schema:

  def test_should_be_able_to_migrate_from_an_empty_schema
    drop_all_tables

    # we shouldn't have any tables
    assert_schema do |s|
    end

    migrate  

    assert_schema do |s|
      s.table :books do |t|
        t.column :id,     :integer
        t.column :title,  :string
        t.column :author, :string
      end

      s.table :reviews do |t|
        t.column :id,      :integer
        t.column :book_id, :integer
        t.column :body,    :text
        t.column :rating,  :integer
        t.index  :book_id, :name => 'index_book_id_on_reviews'
      end
    end
  end


The *migrate* helper can also be useful for testing data tranformation migrations:

  def test_should_get_rid_of_bad_data
    drop_all_tables
    migrate :version => 7
    Book.reset_column_information
    book = Book.create! :title => "bad title\nwith\todd    spacing"
    migrate :version => 8 # should cleanse spacing in book titles
    book.reload
    assert_equal "bad title with odd spacing", book.title
  end 
