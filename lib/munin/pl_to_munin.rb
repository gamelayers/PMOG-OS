#!/usr/bin/env ruby

require 'rubygems'
require 'production_log/analyzer'

file_name = ARGV.shift

# The call to the script must include the file name.
if file_name.nil? then
  puts "Usage: #{$0} file_name"
  exit 1
end

# Gets the maximun value in a set of values
def max_value(records)
  times = records.values.flatten
  return times.max
end

# Gets the minimum value in a set of values
def min_value(records)
  times = records.values.flatten
  return times.min
end

# Gets the average value in a set of values
def avg_value(records)
  times = records.values.flatten
  return times.average
end

# Gets the standard deviation in a set of values
def std_deviation_value(records)
  times = records.values.flatten
  return times.standard_deviation
end

# Creates a new log analyzer from the supplied file (see gem production_log_analyzer)
@analyzer = Analyzer.new file_name
@analyzer.process

# The report type is specified by the -r switch when invoking
ARGV.shift #-r
report_type = ARGV.shift

# Return the proper data based on the requested report
case report_type
  when "request":   puts "max.value " + max_value(@analyzer.request_times).to_s + "\n" + 
                         "min.value " + min_value(@analyzer.request_times).to_s + "\n" + 
                         "avg.value " + avg_value(@analyzer.request_times).to_s + "\n" +
                         "dev.value " + std_deviation_value(@analyzer.request_times).to_s
  when "rendering": puts "max.value " + max_value(@analyzer.render_times).to_s + "\n" + 
                         "min.value " + min_value(@analyzer.render_times).to_s + "\n" + 
                         "avg.value " + avg_value(@analyzer.render_times).to_s + "\n" +
                         "dev.value " + std_deviation_value(@analyzer.render_times).to_s
else                puts "error"
end
