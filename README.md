# Fixer

Application providing asynchronous media file processing.

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


### Get started!
```
git clone git@github.com:PRX/fixer.prx.org.git
cd fixer.prx.org
bundle install
rake db:create
rake db:migrate
```

### Services
Fixer requires credentials to the following, provided as environment variables:
* Internet Archive (S3-like API)
* Open Calais
* Yahoo Content Analysis
* AWS S3 (via credentials or EC2 IAM role)

### Update .env
In development, environment variables provided using the dotenv gem:
```
cp env-example .env
vi .env
```

## Copyright
&copy; Copyright PRX, Public Radio Exchange https://www.prx.org

## License
Fixer is offered under the [AGPL 3.0](http://opensource.org/licenses/AGPL-3.0)
