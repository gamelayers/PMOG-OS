#!/bin/bash
# Housekeeping
(cd /data/pmog/current; ./script/runner SqlProfiler.wipe -e production) >> /dev/null 2>&1
(cd /data/pmog/current; ./script/runner Cron.wipe_exceptions -e production) >> /dev/null 2>&1
(cd /data/pmog/current; ./script/runner Cron.wipe_bj_archives -e production) >> /dev/null 2>&1
(cd /data/pmog/current; ./script/runner -e production "SessionCleaner.remove_stale_sessions") >> /dev/null 2>&1
