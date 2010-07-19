#!/usr/bin/env ruby

# munin plugin to render rails response time graphs
# link to /etc/munin/plugins/rendering_response_time and /etc/munin/plugins/request_response_time

# We'll use the file name a couple of times so we'll extract it here to keep ourselves DRY
@file_name = File.basename($0)

# Standard Munin plugin minutiae
def config
  title = @file_name.split('_').map{|s| s.capitalize }.join(' ')
  config=<<__END_CONFIG__
graph_title #{title}
graph_vlabel Response Time (seconds)
graph_category rails
max.label Maximum
min.label Minimum
avg.label Average
dev.label Standard Deviation
__END_CONFIG__
  puts config
end

# This is where we call the script that gets us the values from the log file
def get_data
  puts IO.popen("/data/pmog/current/lib/munin/pl_to_munin.rb /data/pmog/shared/log/production.log -r #{@file_name.split('_')[0]}").read
end

# what to call based on the arguments
case ARGV.first
  when 'config'
  config
else
  get_data
end
