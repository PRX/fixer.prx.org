# From https://github.com/phusion/baseimage
# baseimage image version 0.9.15
FROM phusion/baseimage:0.9.15
MAINTAINER PRX <sysadmin@prx.org>

# Set correct environment variables.
ENV HOME /root
ENV RAILS_ENV production

# Use baseimage-docker's init process.
CMD ["/sbin/my_init"]


### Prepare

# add scripts
RUN mkdir /fixer_scripts
ADD ./scripts/* /fixer_scripts/

# add the new user
RUN /fixer_scripts/appuser.sh

# add ruby repo
RUN apt-get install software-properties-common
RUN apt-add-repository ppa:brightbox/ruby-ng

# basics
RUN apt-get update -qq && apt-get install -y build-essential

# git
RUN apt-get install -y git


### Install Ruby

# ruby 2.2
RUN fixer_scripts/ruby2.2.sh

# nokogiri dependency
RUN apt-get install -y libxml2-dev libxslt1-dev

# redis
RUN apt-get install -y redis-tools

# postgres
RUN apt-get install -y libpq-dev

## For all kinds of stuff.
RUN apt-get install -y zlib1g-dev

# libsndfile for ruby_audio gem (waveformjson depends on it)
RUN apt-get install -y libsndfile1-dev


### Install Media Apps

# media
RUN apt-get install -y imagemagick libsox-fmt-all lame mp3val sox madplay twolame flac

# install ffmpeg
RUN /fixer_scripts/ffmpeg.sh


### Deploy Fixer

# application home
ENV APP_HOME /home/app/webapp
RUN mkdir $APP_HOME
RUN chown -R app:app $APP_HOME
WORKDIR $APP_HOME
ADD Gemfile $APP_HOME/
ADD Gemfile.lock $APP_HOME/
RUN sudo -u app bundle install --deployment --without development test

ADD . $APP_HOME
RUN chown -R app:app $APP_HOME

# add runit for the worker process
RUN mkdir /etc/service/worker
ADD worker.sh /etc/service/worker/run
RUN chmod +x /etc/service/worker/run


### Clean

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
