# Fixer

Application providing asynchronous media file processing.
Jobs are submitted via a REST API to the master application that delegates processing to any number of worker processes using messages on prioritized queues.  Workers process files and save the results to number of destinations, updating the master, and sending webhook notifications.

## Install

### Install basics
* Ruby (tested on 2.1)
* Postgres (9.3.4, needs to support uuid type extension)
* gems: bundler, rake

### Install media tools
Fixer uses the [audio_monster](https://github.com/PRX/audio_monster) gem which relies on many command line tools to process media. Below is the list of tools to install:
```
brew install lame
brew install flac
brew install sox
brew install twolame --frontend
brew install madplay
brew install mp3val
brew install ffmpeg
```

For images you also need the ImageMagick or GraphicsMagick command-line tool.
```
brew install imagemagick
```

### Configuration
The `dotenv` gem is used for development, and a sample `env-example` file is included with the list of keys.
```
cp env-example .env
vi .env
```

### Service credentials
Fixer requires credentials to the following, provided as environment variables.

* Internet Archive (S3-like API)
* Open Calais
* Yahoo Content Analysis
* AWS S3 (via credentials or EC2 IAM role)

### Application code
```
git clone git@github.com:PRX/fixer.prx.org.git
cd fixer.prx.org
bundle install
rake db:create
rake db:migrate
```

## Description

Fixer was designed as an application to process media files.
A user create a an application with a set of oAuth credentials (id and secret).
Using these credentials, jobs can be created for fixer to work on.

Each job has:
* A `original` url for the media file to be worked on.
* A `job_type` to indicate what type of media file this is (e.g. text, audio, etc.)
* One or more tasks to perform work on that media file.

Each task has:
* A `task_type`, indicating what work should be done (transcode, cut, concatenate with other files)
* A `destination` url that indicates where the product of that work should be saved.
* A callback url to send back notifications (e.g. a webhook or email) of status and completion

By default, tasks within a job are run in parallel, but they can also run serially by creating a Sequence.
Each Sequence is a kind of Task, and has:
* One or more tasks to perform work on that media file in that order by a worker
* A callback url to send back notifications (e.g. a webhook or email) of status and completion
* The input source for a task will be the output of the prior task

## Structure

Fixer is made up of a `master` web application and `workers` that asynchronously process jobs.

The `master` is a Rails web application providing an oAuth2 REST API for managing jobs, and asynchronous processes that handle task updates from workers.  When jobs are created or retried, the `master` initiates processing by creating a prioritized message for each task in a job.
The `master` stores information about Jobs, Tasks, TaskLogs (updates), and WebHooks in a relational DB (postgres by default).  It also uses the db to store info for users, and oAuth applications, authorizations, and tokens.
To handle scheduled retries, the `master` also has a scheduler (i.e. the `say_when` gem) that allows it set when the retry will run, and runs a process to handle these scheduled actions at the prescribed date and time.

The `worker` is a multi-threaded Ruby process (using `shoryken` or `sidekiq`) that listens on the prioritized task queues, and processes the messages it receives.
As it processes a task, the `worker` sends update messages about the processing to a task update queue.

The only communication between master and the workers are via messages. A task message to a worker contains the complete information about the task necessary for processing the task - it does not connect to any data stores to get information about the task, or to explicitly update the task.


### File Sources and Destinations

Each Job has a source URL, and each of its Tasks can have a destination URL.

The destination URL is where the file to be created or written to as a result of the task.
The scheme for the URL indicates the file should be written to an FTP server ('ftp://user:password@host/path/to/file.mp3), s3 ('s3://bucket/path/to/file.wav), or the Internet Archive ('ia://archive-item/file.ogg').

A source URL can also be to get a file via an http(s) get request, i.e. 'http://' or 'https://'.

For testing purposes (i.e. disabled in production), the 'file://' scheme is supported for using local files as sources and destinations.


### Processing Updates: Callbacks and Retries

When the master receives an update, it always updates its record of the status of the task and overall job.
can schedule a retries on failure, and initiates callbacks via webhooks or  emails.  Callbacks can be specified for each task, a sequence, or a job. For example, if there is a callback on the job, callbacks will only occur when the entire job is complete.  If the callback is on a task, then only changes and completion of that task will cause a callback.

### Worker Library: `sidekiq` || `shoryuken` || `local`

By setting the `WORKER_LIB` you can choose to use either 'shoryken' or 'sidekiq' for messaging and async task processing.

There is also a default 'local' value, for development and testing, where tasks are called synchronously - no messaging or worker process is used at all.

Why not ActiveJob? We are using priorities, which requires specifying which queue a job ends up on, and that is not possible with the ActiveJob interface.


## Copyright
&copy; Copyright PRX, Public Radio Exchange https://www.prx.org


## License
Fixer is offered under the [AGPL 3.0](http://opensource.org/licenses/AGPL-3.0)
