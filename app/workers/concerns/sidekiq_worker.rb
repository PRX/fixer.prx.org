# encoding: utf-8

if ENV['WORKER_LIB'] == 'sidekiq'

require 'sidekiq'
require 'system_information'

module SidekiqWorker

  def self.included(base)
    base.send :include, Sidekiq::Worker
    base.send :extend, ClassMethods
  end

  def perform(*args)
    process(*args)
  end

  def logger
    Sidekiq.logger
  end

  module ClassMethods
    def worker_options(*args)
      sidekiq_options(*args)
    end

    def publish(queue, message, options={})
      client_push('queue' => queue, 'class' => self, 'args' => Array[message])
    end
  end
end

end # if ENV['WORKER_LIB'] == 'sidekiq'
