class AddTraceToSqlProfiler < ActiveRecord::Migration
  def self.up
    add_column :sql_profiler, :trace, :text, :null => true
  end

  def self.down
    remove_column :sql_profiler, :trace
  end
end
