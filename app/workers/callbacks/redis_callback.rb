# encoding: utf-8

require 'json'
require 'rack'
require 'redis'
require 'service_options'

module RedisCallback
  def redis_callback(web_hook)
    uri = URI.parse(web_hook[:url])
    options = redis_options(uri)
    payload = sidekiq_payload(options, web_hook[:message])

    conn = redis(options)
    conn.sadd('queues', options[:queue])
    conn.lpush("queue:#{options[:queue]}", payload)
  end

  def redis(options={})
    @redis ||= Redis.new(options)
  end

  def redis=(redis)
    @redis = redis
  end

  def redis_options(uri)
    result = {}
    so = ServiceOptions.service_options(:redis)
    params = Rack::Utils.parse_nested_query(uri.query)
    uri.query = nil

    if uri.user || uri.password || uri.host
      result[:url] = uri.to_s
    else
      result[:url] = so[:url]
    end

    result[:queue] = params['queue'] || so[:queue] || 'fixer_queue'
    result[:worker] = params['worker'] || so[:worker] || 'FixerCallbackWorker'

    result
  end

  # could make into settings, if people need it
  def sidekiq_payload(options, message)
    {
      'queue'       => options[:queue],
      'jid'         => SecureRandom.hex(12),
      'enqueued_at' => Time.now.to_f,
      'class'       => options[:worker],
      'args'        => [message],
      'backtrace'   => true,
      'retry'       => 3
    }.to_json
  end
end
