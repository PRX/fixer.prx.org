require 'fixer_constants'
require 'system_information'

require 'aws-sdk-core'

namespace :sqs do

  desc 'Create required SQS queues'
  task :create, [:env] => [:environment] do |t, args|

    env = args[:env] || Rails.env

    default_options = {
      'DelaySeconds' => "0",
      'MaximumMessageSize' => "#{(256 * 1024)}",
      'VisibilityTimeout' => "#{1.hour.seconds.to_i}",
      'ReceiveMessageWaitTimeSeconds' => "0",
      'MessageRetentionPeriod' => "#{1.week.seconds.to_i}"
    }

    # create the update queue and DLQ
    dlq_arn = create_dlq("#{env}_fixer_update", default_options)
    create_queue("#{env}_fixer_update", dlq_arn, default_options)

    # create the priority queues
    dlq_arn = create_dlq("#{env}_fixer", default_options)
    (1..FixerConstants::MAX_PRIORITY).each do |p|
      create_queue("#{env}_fixer_p#{p}", dlq_arn, default_options)
    end
  end

  def create_queue(queue, dlq_arn, options={})
    sqs = Aws::SQS::Client.new
    options = options.merge('RedrivePolicy' => %Q{{"maxReceiveCount":"10", "deadLetterTargetArn":"#{dlq_arn}"}"})
    q = sqs.create_queue(queue_name: queue, attributes: options)
    puts "created queue: #{q.inspect}"
  end

  def create_dlq(queue, options)
    sqs = Aws::SQS::Client.new
    dlq_name = "#{queue}_failures"
    dlq = sqs.create_queue(queue_name: dlq_name, attributes: options)
    puts "created DLQ: #{dlq.inspect}"
    attrs = sqs.get_queue_attributes(queue_url: dlq.queue_url, attribute_names: ['QueueArn']) rescue nil
    attrs.attributes['QueueArn']
  end
end
