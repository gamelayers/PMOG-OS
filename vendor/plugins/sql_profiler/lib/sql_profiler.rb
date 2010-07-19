class SqlProfiler < ActiveRecord::Base
  set_table_name "sql_profiler"

  def self.top(count=100)
    SqlProfiler.find_by_sql( [ "SELECT count(*) AS count_all, query, num_rows, trace FROM sql_profiler GROUP BY query ORDER BY num_rows DESC LIMIT ?", count ] )
  end

  # To be run frequently, from cron most likely
  def self.wipe
    SqlProfiler.execute( 'delete from sql_profiler' )
  end
end