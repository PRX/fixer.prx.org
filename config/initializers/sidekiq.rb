if ENV['WORKER_LIB'] == 'sidekiq'

require 'sidekiq'
require 'service_options'

redis_options = ServiceOptions.service_options(:redis).symbolize_keys || {}

Sidekiq.configure_client do |config|
  config.redis = redis_options
end

Sidekiq.configure_server do |config|
  config.redis = redis_options

  if defined?(ActiveRecord)
    database_url = ENV['DATABASE_URL']
    if database_url
      ENV['DATABASE_URL'] = "#{database_url}?pool=#{ENV['SIDEKIQ_DATABASE_POOL_SIZE']}"
      ActiveRecord::Base.establish_connection
    end
  end
end

Sidekiq.default_worker_options = { 'backtrace' => 10 }

end
