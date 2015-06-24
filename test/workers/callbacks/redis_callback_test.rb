require 'test_helper'
require 'callbacks/redis_callback'

class RedisCallbackTest < ActiveSupport::TestCase

  class RedisCallbackTestClass
    include RedisCallback

    def logger
      Rails.logger
    end
  end

  let(:callback) { RedisCallbackTestClass.new }

  let(:web_hook) do
    {
      url: 'redis://127.0.0.1:6379/?queue=cb&worker=w',
      message: { result: 'success' }.to_json
    }
  end

  let(:redis) do
    redis = Minitest::Mock.new
    redis.expect(:sadd, true, [String, String])
    redis.expect(:lpush, true, [String, String])
    redis
  end

  it 'gets redis options from a uri' do
    options = callback.redis_options(URI.parse(web_hook[:url]))
    options[:url].must_equal 'redis://127.0.0.1:6379/'
    options[:queue].must_equal 'cb'
    options[:worker].must_equal 'w'
  end

  it 'gets redis options from service options' do
    options = callback.redis_options(URI.parse('redis:///'))
    options[:url].must_equal 'redis://localhost:6379/'
    options[:queue].must_equal 'test_fixer_queue'
    options[:worker].must_equal 'TestFixerWorker'
  end

  it 'can call an redis callback' do
    callback.redis = redis
    callback.redis_callback(web_hook)
  end
end
