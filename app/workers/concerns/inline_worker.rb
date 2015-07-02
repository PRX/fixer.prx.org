# encoding: utf-8

module InlineWorker

  def self.included(base)
    base.send :extend, ClassMethods
  end

  def perform(message)
    process(message)
  end

  def logger
    @logger ||= Logger.new('/dev/null')
  end

  module ClassMethods
    def worker_options(options={})
      @inline_options = options
    end

    def get_inline_options
      @inline_options
    end

    def publish(queue, message, options={})
      new.perform(message)
    end
  end
end
