class SqlProfiler < ActiveRecord::Migration
  def self.up
    create_table :sql_profiler do |t|
      t.column :query, :text, :null => false
    end

    execute( "CREATE INDEX `index_sql_profiler_on_sql` ON sql_profiler ( `query`(255) )" )
  end

  def self.down
    drop_table :sql_profiler
  end
end
