# Fixer

Application providing asynchronous media file processing.

## Install

### Install basics
* Ruby (tested on 2.1)
* Postgres (9.3.4, needs to support uuid type extension)
* gems: bundler, rake

### Install media tools
```
brew install lame
brew install flac
brew install sox
brew install twolame --frontend
brew install madplay
brew install mp3val
brew install ffmpeg
```

### Get started!
```
git clone git@github.com:PRX/fixer.prx.org.git
cd fixer.prx.org
bundle install
rake db:create
rake db:migrate
```

### Services
Fixer requires credentials to the following:
* Internet Archive (S3-like API)
* Open Calais
* Yahoo Content Analysis
* AWS S3 (via credentials or EC2 IAM role)

### Update .env
```
cp env-example .env
vi .env
```

# Development notes

## Changes from the original app
Done
* Use uuid for jobs, allow them to be submitted when jobs created
* Use an enum for status
* remove client application based service/storage credentials - unused

Planned
* Submit jobs via messages, not HTTP/API calls
* Fix reliance on serialized task status update


## Stuff that needs addressing still

* Authentication
  oauth against prx.org with omniauth
  2-legged-oauth for the API (client credentials flow, basically)

* Messaging
  activemessaging and SQS, considering shoryuken

* Worker Processes
  using celluloid based processor for processing, single threaded poller for updates

* Scheduling
  say_when
