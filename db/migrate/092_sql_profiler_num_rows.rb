class SqlProfilerNumRows < ActiveRecord::Migration
  def self.up
    add_column :sql_profiler, :num_rows, :integer
  end

  def self.down
    remove_column :sql_profiler, :num_rows
  end
end
