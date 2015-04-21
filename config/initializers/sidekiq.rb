if ENV['WORKER_LIB'] == 'sidekiq'

require 'sidekiq'

if defined?(ActiveRecord)
  Sidekiq.configure_server do |config|
    database_url = ENV['DATABASE_URL']
    if database_url
      ENV['DATABASE_URL'] = "#{database_url}?pool=#{ENV['SIDEKIQ_DATABASE_POOL_SIZE']}"
      ActiveRecord::Base.establish_connection
    end
  end
end

Sidekiq.default_worker_options = { 'backtrace' => 10 }

end
