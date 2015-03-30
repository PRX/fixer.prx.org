#!/bin/bash
# https://github.com/phusion/passenger-docker/blob/master/image/ruby2.2.sh
set -e
source /fixer_scripts/buildconfig
set -x

minimal_apt_get_install ruby2.2 ruby2.2-dev
update-alternatives --install /usr/bin/gem gem /usr/bin/gem2.2 191
update-alternatives \
  --install /usr/bin/ruby ruby /usr/bin/ruby2.2 61 \
  --slave /usr/bin/erb erb /usr/bin/erb2.2 \
  --slave /usr/bin/testrb testrb /usr/bin/testrb2.2 \
  --slave /usr/bin/rake rake /usr/bin/rake2.2 \
  --slave /usr/bin/irb irb /usr/bin/irb2.2 \
  --slave /usr/bin/rdoc rdoc /usr/bin/rdoc2.2 \
  --slave /usr/bin/ri ri /usr/bin/ri2.2 \
  --slave /usr/share/man/man1/ruby.1.gz ruby.1.gz /usr/share/man/man1/ruby2.2.*.gz \
  --slave /usr/share/man/man1/erb.1.gz erb.1.gz /usr/share/man/man1/erb2.2.*.gz \
  --slave /usr/share/man/man1/irb.1.gz irb.1.gz /usr/share/man/man1/irb2.2.*.gz \
  --slave /usr/share/man/man1/rake.1.gz rake.1.gz /usr/share/man/man1/rake2.2.*.gz \
  --slave /usr/share/man/man1/ri.1.gz ri.1.gz /usr/share/man/man1/ri2.2.*.gz
gem2.2 install rake bundler --no-rdoc --no-ri

echo "gem: --no-ri --no-rdoc --bindir /usr/local/bin" > /etc/gemrc

## Fix shebang lines in rake and bundler so that they're run with the currently
## configured default Ruby instead of the Ruby they're installed with.
sed -i 's|/usr/bin/env ruby.*$|/usr/bin/env ruby|; s|/usr/bin/ruby.*$|/usr/bin/env ruby|' \
  /usr/local/bin/rake /usr/local/bin/bundle /usr/local/bin/bundler

## Set the latest available Ruby as the default.
/fixer_scripts/ruby-switch --set ruby2.2
