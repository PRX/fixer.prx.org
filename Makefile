test: clean
	docker-compose run fixer testsetup test

check:
	rubocop

clean:
	sudo rm -rf log/*log
	sudo rm -rf tmp/ && mkdir -p tmp/audio_monster && chmod -R 777 tmp
	sudo rm -rf coverage && mkdir coverage && chmod 777 coverage

# example:
#  make onetest TEST=test/foo.rb TESTNAME=bar
#
LOCAL_POSTGRES_USER := ${USER}
onetest: clean
	DB_PORT_5432_TCP_ADDR=/var/run/postgresql DB_ENV_POSTGRES_USER=${LOCAL_POSTGRES_USER} RAILS_ENV=test bundle exec rake test TESTOPTS='--name /${TESTNAME}/'

localtest: clean
	DB_PORT_5432_TCP_ADDR=/var/run/postgresql DB_ENV_POSTGRES_USER=${LOCAL_POSTGRES_USER} RAILS_ENV=test bundle exec rake test

stop:
	docker-compose stop

build:
	docker-compose build

startdb:
	docker-compose start db

setup:
	docker-compose run fixer setup

install: build startdb setup

.PHONY: test clean check install
