# encoding: utf-8

if ENV['WORKER_LIB'] == 'shoryuken'

require 'shoryuken'
require 'system_information'

module ShoryukenWorker

  def self.included(base)
    base.send :include, Shoryuken::Worker
    base.send :extend, ClassMethods
  end

  def perform(sqs_msg, body)
    @message = sqs_msg
    process(body)
  end

  def logger
    Shoryuken.logger
  end

  module ClassMethods
    def worker_options(*args)
      shoryuken_options(*args)
    end

    def publish(queue, message, options={})
      options[:message_attributes] ||= {}
      options[:message_attributes]['shoryuken_class'] = {
        string_value: self.to_s,
        data_type: 'String'
      }
      options[:message_body] = message.to_json

      sqs_queue = Shoryuken::Client.queues(env_prefix_queue(queue))
      sqs_queue.send_message(options)
    end

    def env_prefix_queue(queue)
      "#{SystemInformation.env}_#{queue}"
    end
  end
end

end # if ENV['WORKER_LIB'] == 'shoryuken'