#!/bin/sh
set -e

cd $APP_HOME
exec /sbin/setuser app bundle exec rake say_when:start 2>&1
