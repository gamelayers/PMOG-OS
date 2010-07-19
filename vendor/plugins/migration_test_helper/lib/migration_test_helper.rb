#--
# Copyright (c) 2007 Micah Alles, Patrick Bacon, David Crosby
# 
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

require 'test/unit/assertions'

module MigrationTestHelper 
  def self.migration_dir
    @migration_dir || File.expand_path(RAILS_ROOT + '/db/migrate')
  end

  #
  # sets the directory in which the migrations reside to be run with migrate
  #
  def self.migration_dir=(new_dir)
    @migration_dir = new_dir
  end

  #
  # verifies the schema exactly matches the one specified (schema_info does not have to be specified)
  # 
  #   assert_schema do |s|
  #     s.table :dogs do |t|
  #       t.column :id,   :integer, :default => 2
  #       t.column :name, :string
  #     end
  #   end
  #
  def assert_schema
    schema = Schema.new
    yield schema
    schema.verify
  end

  #
  # verifies a single table exactly matches the one specified
  # 
  #   assert_table :dogs do |t|
  #     t.column :id,   :integer, :default => 2
  #     t.column :name, :string
  #   end
  #
  def assert_table(name)
    table = Table.new(name)
    yield table
    table.verify
  end

  #
  # drops all tables in the database
  # 
  def drop_all_tables
    ActiveRecord::Base.connection.tables.each do |table|
      ActiveRecord::Base.connection.drop_table(table)
    end
  end

  #
  # executes your migrations
  #
  #   migrate                # same as rake db:migrate
  #
  # Options are:
  # * :version - version to migrate to (same as VERSION=.. option to rake db:migrate)
  # * :verbose - print migration status messages to STDOUT, defaults to false
  # 
  def migrate(opts={})
    old_verbose = ActiveRecord::Migration.verbose
    ActiveRecord::Migration.verbose = opts[:verbose].nil? ? false : opts[:verbose]
    version = opts[:version] ? opts[:version].to_i : nil
    ActiveRecord::Migrator.migrate(MigrationTestHelper.migration_dir, version)
  ensure
    ActiveRecord::Migration.verbose = old_verbose
  end

  module Connection #:nodoc:
    def conn
      ActiveRecord::Base.connection
    end
  end

  class Schema
    include Connection
    include Test::Unit::Assertions

    def initialize #:nodoc:
      @tables = []
    end

    def table(name)
      table = Table.new(name)
      yield table
      table.verify
      @tables << table
    end

    def verify #:nodoc:
      actual_tables = conn.tables.reject {|t| t == 'schema_info' }
      expected_tables = @tables.map {|t| t.name }
      assert_equal expected_tables.sort, actual_tables.sort, 'wrong tables in schema'
    end
  end

  class Table
    include Connection
    include Test::Unit::Assertions
    attr_reader :name

    def initialize(name) #:nodoc:
      @name = name.to_s
      @columns = []
      @indexes = []
      assert conn.tables.include?(@name), "table <#{@name}> not found in schema"
    end

    def column(colname,type,options={})
      colname = colname.to_s
      @columns << colname
      col = conn.columns(name).find {|c| c.name == colname }
      assert_not_nil col, "column <#{colname}> not found in table <#{self.name}>"
      assert_equal type, col.type, "wrong type for column <#{colname}> in table <#{name}>"
      options.each do |k,v|
        k = k.to_sym; actual = col.send(k); actual = actual.is_a?(String) ? actual.sub(/'$/,'').sub(/^'/,'') : actual
        assert_equal v, actual, "column <#{colname}> in table <#{name}> has wrong :#{k}"
      end
    end

    def index(column_name, options = {})
      @indexes << "name <#{options[:name]}> columns <#{Array(column_name).join(",")}> unique <#{options[:unique] == true}>" 
    end

    def verify #:nodoc:
      actual_columns = conn.columns(name).map {|c| c.name }
      assert_equal @columns.sort, actual_columns.sort, "wrong columns for table: <#{name}>"

      actual_indexes = conn.indexes(@name).collect { |i| "name <#{i.name}> columns <#{i.columns.join(",")}> unique <#{i.unique}>" }
      assert_equal @indexes.sort, actual_indexes.sort, "wrong indexes for table: <#{name}>"
    end
  end
end
