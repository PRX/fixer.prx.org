# encoding: utf-8

class BaseWorker

  include FixerConstants

  def perform(*args)
  end

  def self.worker_lib
    ENV['FIXER_WORKER_LIB'] || 'local'
  end

  if worker_lib == 'sidekiq'
    include Sidekiq::Worker
  elsif worker_lib == 'shoryken'
    include Shoryuken::Worker
  end

  def self.worker_options(*args)
    send("#{worker_lib}_options", *args)
  end

  def self.local_options(options={})
    @local_options = options
  end

  def self.publish(queue, message, options={})
    if worker_lib == 'sidekiq'
      client_push('queue' => queue, 'class' => self, 'args' => message)
    elsif worker_lib == 'shoryken'
      options[:message_attributes] ||= {}
      options[:message_attributes]['shoryuken_class'] = {
        string_value: self.to_s,
        data_type: 'String'
      }
      Shoryuken::Client.send_message('queue', message, options)
    elsif worker_lib == 'local'
      new.perform(message)
    end
  end
end
