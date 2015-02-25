# encoding: utf-8

# allows three options for workers: local (synch call, default), sidekiq, and shoryken
class BaseWorker

  include FixerConstants

  def perform(*args)
  end

  def self.worker_lib
    ENV['WORKER_LIB'] || 'local'
  end

  if worker_lib == 'sidekiq'
    include Sidekiq::Worker
  elsif worker_lib == 'shoryken'
    include Shoryuken::Worker
  else
    include LocalWorker
  end

  def self.worker_options(*args)
    send("#{worker_lib}_options", *args)
  end

  def self.local_options(options={})
    @local_options = options
  end

  def self.get_local_options
    @local_options
  end

  def self.publish(queue, message, options={})
    send("#{worker_lib}_publish", queue, message, options)
  end

  def self.local_publish(queue, message, options)
    new.perform(message)
  end

  def self.sidekiq_publish(queue, message, options)
    client_push('queue' => queue, 'class' => self, 'args' => Array[message])
  end

  def self.shoryuken_publish(queue, message, options)
    options[:message_attributes] ||= {}
    options[:message_attributes]['shoryuken_class'] = {
      string_value: self.to_s,
      data_type: 'String'
    }
    Shoryuken::Client.send_message(shoryuken_q(queue), message, options)
  end

  def self.shoryuken_q(queue)
    "#{SystemInformation.env}_#{queue}"
  end
end
