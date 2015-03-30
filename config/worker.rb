if ENV['RAILS_ENV'] == 'development'
  require 'dotenv'
  Dotenv.load
end

app_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))
ENV['APP_ROOT'] ||= app_root
$:.unshift(app_root)

# set temp file locations
ENV['NU_WAV_TMP_DIR'] ||= File.join(app_root, 'tmp', 'nu_wav')
ENV['GOOGLE_SPEECH_TMP_DIR'] ||= File.join(app_root, 'tmp', 'google_speech')

# load worker initializer
require File.join(app_root, "config/initializers/#{ENV['WORKER_LIB']}.rb")

# load the code
['lib', 'app/processors', 'app/workers/concerns', 'app/workers'].each do |path|
  ruby_path = File.join(app_root, path)
  $:.unshift(ruby_path)
  Dir["#{ruby_path}/**/*.rb"].each {|file| require file }
end
