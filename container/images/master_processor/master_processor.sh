#!/bin/sh
set -e

cd $APP_HOME
exec /sbin/setuser app bundle exec $WORKER_LIB -R -C $APP_HOME/config/$WORKER_LIB/master.yml 2>&1

