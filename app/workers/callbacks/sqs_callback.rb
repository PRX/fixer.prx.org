# encoding: utf-8

require 'aws-sdk-core'
require 'service_options'

module SqsCallback
  def sqs_callback(web_hook)
    uri = URI.parse(web_hook[:url])

    sqs = sqs(sqs_options(uri))

    queue = uri.path[1..-1]
    begin
      sqs.create_queue(queue_name: queue, attributes: queue_options)
    rescue Aws::SQS::Errors::QueueAlreadyExists => e
      logger.info("sqs queue for callback already exists: #{queue}")
    end

    queue_url = sqs.get_queue_url(queue_name: queue).queue_url

    sqs.send_message(queue_url: queue_url, message_body: web_hook[:message])
  end

  def sqs(options={})
    @sqs ||= Aws::SQS::Client.new(options)
  end

  def sqs=(sqs)
    @sqs = sqs
  end

  def sqs_options(uri)
    so = ServiceOptions.awssdk_service_options
    so.merge(ServiceOptions.awssdk_options_for_uri(uri))
  end

  def queue_options
    {
      'DelaySeconds' => "0",
      'MaximumMessageSize' => "#{(256 * 1024)}",
      'VisibilityTimeout' => "#{1.hour.seconds.to_i}",
      'ReceiveMessageWaitTimeSeconds' => "0",
      'MessageRetentionPeriod' => "#{1.week.seconds.to_i}"
    }
  end
end
