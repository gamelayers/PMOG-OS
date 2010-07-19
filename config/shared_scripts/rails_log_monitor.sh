#! /bin/sh

# Provides:          Rails log monitoring
# Short-Description: Start the rails log monitor

set -e

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
DESC="Rails Log Monitor"
NAME=`basename $0`
SCRIPTNAME=/etc/init.d/$NAME
APPLICATION=pmog

RUBY=/usr/bin/ruby
RAILS_ROOT=/data/$APPLICATION/current; export RAILS_ROOT
RAILS_ENV=production; export RAILS_ENV
DAEMON_CTL_SCRIPT=$RAILS_ROOT/lib/daemons/rails_log_monitor_ctl.rb

ACTION="$1"
case "$ACTION" in
  start|stop|restart|run|zap)
    echo -n "$ACTION-ing $DESC: $NAME"
    $RUBY $DAEMON_CTL_SCRIPT $ACTION
    echo "."
    ;;
    
  *)
    echo "Usage: $NAME {start|stop|restart|run|zap}" >&2
    exit 3
    ;;
esac

exit 0
