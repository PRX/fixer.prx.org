#!/bin/sh
set -e

cd $APP_HOME
exec /sbin/setuser app bundle exec $WORKER_LIB -C $APP_HOME/config/$WORKER_LIB/worker.yml -r $APP_HOME/config/worker.rb 2>&1
