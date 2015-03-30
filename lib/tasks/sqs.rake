require 'fixer_constants'
require 'system_information'

require 'aws-sdk-core'
require 'aws-sdk-resources'

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
    update_dlq = create_dlq("#{env}_fixer_update", default_options)
    create_queue("#{env}_fixer_update", update_dlq, default_options)

    # create the priority queues
    dlq = create_dlq("#{env}_fixer", default_options)
    (1..FixerConstants::MAX_PRIORITY).each do |p|
      create_queue("#{env}_fixer_p#{p}", dlq, default_options)
    end
  end

  def create_queue(queue, dlq, options={})
    sqs_resource = Aws::SQS::Resource.new
    q = sqs_resource.get_queue_by_name(queue_name: queue) rescue nil
    if q
      puts "Queue '#{queue}'' already exists: #{q.inspect}"
    else
      options = options.merge('RedrivePolicy' => %Q{{"maxReceiveCount":"10", "deadLetterTargetArn":"#{dlq.arn}"}"})
      puts "create #{queue}: #{options.inspect}"
      q = sqs_resource.create_queue(queue_name: queue, attributes: options)
    end
    q
  end

  def create_dlq(queue, options)
    sqs_resource = Aws::SQS::Resource.new
    dlq_name = "#{queue}_failures"
    dlq = sqs_resource.get_queue_by_name(queue_name: dlq_name) rescue nil
    if dlq
      puts "DLQ '#{queue}'' already exists: #{dlq.inspect}"
    else
      puts "create DLQ #{dlq_name}: #{options.inspect}"
      dlq = sqs_resource.create_queue(queue_name: dlq_name, attributes: options)
    end
    dlq
  end
end
