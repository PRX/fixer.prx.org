# From https://github.com/phusion/passenger-docker
# Ruby 2.2
# passenger-docker image version 0.9.15
FROM phusion/passenger-ruby22:0.9.15
MAINTAINER PRX <sysadmin@prx.org>

### Initialize

# Set correct environment variables.
ENV HOME /root
ENV RAILS_ENV production

# Add a startup script for the app
RUN mkdir -p /etc/my_init.d
COPY app_init.sh /etc/my_init.d/app_init.sh
RUN chmod +x /etc/my_init.d/app_init.sh

# Use baseimage-docker's init process.
CMD ["/sbin/my_init"]


### Installs

# basics
RUN apt-get update -qq && apt-get install -y build-essential

# redis (make this conditional)
RUN apt-get install -y redis-tools

# postgres
RUN apt-get install -y libpq-dev

# nokogiri dependency
RUN apt-get install -y libxml2-dev libxslt1-dev

# libsndfile for ruby_audio gem (waveformjson depends on it)
RUN apt-get install -y libsndfile1-dev

# js runtime
RUN apt-get install -y nodejs

### Clean

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


### Configure

# Configure nginx
COPY app_env.conf /etc/nginx/main.d/app_env.conf
COPY webapp.conf /etc/nginx/sites-enabled/webapp.conf

### Deploy Fixer

# application home
ENV APP_HOME /home/app/webapp
RUN mkdir -p $APP_HOME
WORKDIR $APP_HOME
ADD Gemfile $APP_HOME/
ADD Gemfile.lock $APP_HOME/
RUN chown -R app:app $APP_HOME
RUN sudo -u app bundle install --deployment --without development test
ADD . $APP_HOME
RUN chown -R app:app $APP_HOME
RUN sudo -u app bundle exec rake assets:precompile --trace

# add say_when to runit
RUN mkdir -p /etc/service/say_when
ADD say_when.sh /etc/service/say_when/run
RUN chmod +x /etc/service/say_when/run

# Nginx and Passenger are disabled by default. Enable them like so:
RUN rm -f /etc/service/nginx/down
RUN rm /etc/nginx/sites-enabled/default
