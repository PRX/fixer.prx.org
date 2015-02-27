require 'fixer_constants'
require 'system_information'

require 'aws-sdk-core'
require 'aws-sdk-resources'

namespace :sqs do

  desc 'Create required SQS queues'
  task :create => :environment do

    default_options = {
      'DelaySeconds' => "0",
      'MaximumMessageSize' => "#{(256 * 1024)}",
      'VisibilityTimeout' => "#{1.hour.seconds.to_i}",
      'ReceiveMessageWaitTimeSeconds' => "0",
      'MessageRetentionPeriod' => "#{1.week.seconds.to_i}"
    }

    # create the update queue and DLQ
    update_dlq = create_dlq('fixer_update', default_options)
    create_queue('fixer_update', update_dlq, default_options)

    # create the priority queues
    dlq = create_dlq('fixer', default_options)
    (1..FixerConstants::MAX_PRIORITY).each do |p|
      create_queue("fixer_p#{p}", dlq, default_options)
    end
  end

  def create_queue(queue, dlq, options={})
    sqs_resource = Aws::SQS::Resource.new
    q_name = qn(queue)
    q = sqs_resource.get_queue_by_name(queue_name: q_name) rescue nil
    if q
      puts "Queue '#{queue}'' already exists: #{q.inspect}"
    else
      options = options.merge('RedrivePolicy' => %Q{{"maxReceiveCount":"10", "deadLetterTargetArn":"#{dlq.arn}"}"})
      puts "create #{q_name}: #{options.inspect}"
      q = sqs_resource.create_queue(queue_name: q_name, attributes: options)
    end
    q
  end

  def create_dlq(queue, options)
    sqs_resource = Aws::SQS::Resource.new
    dlq_name = "#{qn(queue)}_failures"
    dlq = sqs_resource.get_queue_by_name(queue_name: dlq_name) rescue nil
    if dlq
      puts "DLQ '#{queue}'' already exists: #{dlq.inspect}"
    else
      puts "create DLQ #{dlq_name}: #{options.inspect}"
      dlq = sqs_resource.create_queue(queue_name: dlq_name, attributes: options)
    end
    dlq
  end

  def qn(n)
    "#{SystemInformation.env}_#{n}"
  end
end
