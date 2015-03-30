# From https://github.com/phusion/passenger-docker
# Ruby 2.2
# passenger-docker image version 0.9.15
FROM phusion/passenger-ruby22:0.9.15
MAINTAINER PRX <sysadmin@prx.org>

# Set correct environment variables.
ENV HOME /root
ENV RAILS_ENV production

# Use baseimage-docker's init process.
CMD ["/sbin/my_init"]


### Installs

# basics
RUN apt-get update -qq && apt-get install -y build-essential

# redis
RUN apt-get install -y redis-tools

# postgres
RUN apt-get install -y libpq-dev

# nokogiri dependency
RUN apt-get install -y libxml2-dev libxslt1-dev

# libsndfile for ruby_audio gem (waveformjson depends on it)
RUN apt-get install -y libsndfile1-dev

### Configure

# Configure nginx
COPY app-env.conf /etc/nginx/main.d/app-env.conf
COPY webapp.conf /etc/nginx/sites-enabled/webapp.conf

### Deploy Fixer

# application home
ENV APP_HOME /home/app/webapp
RUN mkdir $APP_HOME
WORKDIR $APP_HOME
ADD Gemfile $APP_HOME/
ADD Gemfile.lock $APP_HOME/
RUN chown -R app:app $APP_HOME

RUN sudo -u app bundle install --deployment --without development test

ADD . $APP_HOME
RUN chown -R app:app $APP_HOME

# add say_when to runit
RUN mkdir /etc/service/say_when
ADD say_when.sh /etc/service/worker/run

# Nginx and Passenger are disabled by default. Enable them like so:
RUN rm -f /etc/service/nginx/down
RUN rm /etc/nginx/sites-enabled/default


### Clean

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
