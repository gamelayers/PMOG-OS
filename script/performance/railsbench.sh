#! /bin/sh

# Run the following commands if railsbench has not been setup:
#	script/performance/railsbench-0.9.2/bin/railsbench install
#	script/performance/railsbench-0.9.2/bin/railsbench generate_benchmarks
#
# Note that I have patched perf_plot to use a specific fault, so that we
# don't have to rely on the server having it installed.

RAILS_PERF_DATA="/data/pmog/current/public/system/data/"
export RAILS_PERF_DATA

cd /data/pmog/current

script/performance/railsbench-0.9.2/bin/railsbench perf_run 100 "-bm=basic" railsbench-`date +%Y-%m-%d`
script/performance/railsbench-0.9.2/bin/railsbench perf_plot -font_path=fonts/Vera.ttf /data/pmog/current/public/system/data/`date +%m-%d`.basic.railsbench-`date +%Y-%m-%d`.txt -out=/data/pmog/current/public/system/data/railsbench-`date +%Y-%m-%d-%H-%M`.png