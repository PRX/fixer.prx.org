#!/bin/sh

set -ex

chmod 755 /etc/container_environment.sh || true

cd $APP_HOME
# /sbin/setuser app bundle exec rake db:migrate user:create sqs:create || true
