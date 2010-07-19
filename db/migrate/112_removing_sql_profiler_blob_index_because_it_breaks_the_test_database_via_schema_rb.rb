# Sql Profiler uses a BLOB index on the Sql it records, so that it can group by any given query.
# However, the schema that gets automatically dumped to schema.rb can't handle this, and generates
# a standard add_index command, which breaks MySQL as that won't allow simple indexes on Blob columns.
#
# e.g. Mysql::Error: BLOB/TEXT column 'query' used in key specification without a key length: 
# CREATE  INDEX `index_sql_profiler_on_sql` ON `sql_profiler` (`query`)
#
# Since we could really, really use some tests, we'll get rid of the SqlProfiler index, even though
# that could make things slow down when we attempt to use it later. *sigh*

class RemovingSqlProfilerBlobIndexBecauseItBreaksTheTestDatabaseViaSchemaRb < ActiveRecord::Migration
  def self.up
    remove_index :sql_profiler, :sql
  end

  def self.down
    execute( "CREATE INDEX `index_sql_profiler_on_sql` ON sql_profiler ( `query`(255) )" )
  end
end
