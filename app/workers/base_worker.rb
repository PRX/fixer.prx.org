# encoding: utf-8

require 'fixer_constants'
require 'system_information'
require 'service_options'

# allows three options for workers: local (synch call, default), sidekiq, and shoryken
class BaseWorker

  include FixerConstants

  def self.worker_lib
    ENV['WORKER_LIB'] || 'local'
  end

  require "#{worker_lib}_worker"
  include "#{worker_lib}_worker".classify.constantize

  #############

  # def worker_lib
  #   self.class.worker_lib
  # end

  # def perform(*args)
  #   send("#{worker_lib}_perform", *args)
  # end

  # def sidekiq_perform(*args)
  #   process(*args)
  # end

  # def shoryuken_perform(sqs_msg, body)
  #   @fixer_sqs_msg = sqs_msg
  #   process(body)
  # end

  # if worker_lib == 'sidekiq'
  #   include Sidekiq::Worker
  # elsif worker_lib == 'shoryuken'
  #   include Shoryuken::Worker
  #   def logger
  #     Shoryuken::Logging.logger
  #   end
  # else
  #   include LocalWorker
  # end

  # def self.worker_options(*args)
  #   send("#{worker_lib}_options", *args)
  # end

  # def self.local_options(options={})
  #   @local_options = options
  # end

  # def self.get_local_options
  #   @local_options
  # end

  # def self.publish(queue, message, options={})
  #   send("#{worker_lib}_publish", queue, message, options)
  # end

  # def self.local_publish(queue, message, options)
  #   new.perform(message)
  # end

  # def self.sidekiq_publish(queue, message, options)
  #   client_push('queue' => queue, 'class' => self, 'args' => Array[message])
  # end

  # def self.shoryuken_publish(queue, message, options)
  #   options[:message_attributes] ||= {}
  #   options[:message_attributes]['shoryuken_class'] = {
  #     string_value: self.to_s,
  #     data_type: 'String'
  #   }
  #   options[:message_body] = message.to_json

  #   sqs_queue = Shoryuken::Client.queues(shoryuken_q(queue))
  #   sqs_queue.send_message(options)
  # end

  # def self.shoryuken_q(queue)
  #   "#{SystemInformation.env}_#{queue}"
  # end
end
