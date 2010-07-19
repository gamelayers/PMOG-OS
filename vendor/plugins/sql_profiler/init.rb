#if 1 == 2
#  connection = ActiveRecord::Base.connection
#  class << connection
#    alias :original_exec :execute
#  
#    begin
#      @@host = `uname -n`.strip
#    rescue
#      @@host = `hostname`
#    end
#
#    # Disabled
#    @@acceptable_hosts = []
#
#    # Staging only
#    #@@acceptable_hosts = [ 'ey01-s00093' ]
#    #
#    # Production and staging
#    #@@acceptable_hosts = [ 'ey01-s00093', 'ey01-s00094' ]
#    #
#    # Staging and local
#    #@@acceptable_hosts = [ 'ey01-s00093', 'suttree.local' ]
#
#    # Number of rows to exceed before printing a warning to the log
#    @@max_row_warning = 1000
#
#    def execute(query, *name)
#      mysql_result = original_exec(query, *name)
#      if @@acceptable_hosts.include? @@host
#        if mysql_result and mysql_result.num_rows >= @@max_row_warning
#          # It would most acceptable if I could figure out a way to log the params here too.
#          # But I cannot find a way to do it, yet :(
#          trace = caller[2..-1].join( "\n    " ) # from query_trace
#        else
#          trace = nil
#        end
#        original_exec( "INSERT INTO sql_profiler( `query`, `num_rows`, `trace` ) VALUES ( \"#{query}\", #{mysql_result.num_rows}, \"#{trace}\" )" ) rescue nil
#      end
#
#      mysql_result
#    end
#  end
#end