# encoding: utf-8

require 'redis'
require 'service_options'

module RedisCallback
  def redis_callback(web_hook)
    raise NotImplementedError.new('redis callbacks not yet supported')
  end
end
