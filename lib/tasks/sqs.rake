require 'fixer_constants'
require 'system_information'

namespace :sqs do

  desc 'Create required SQS queues'
  task :create => :environment do

    default_options = {
      visibility_timeout: 1.hour.seconds.to_i,
      message_retention_period: 1.week.seconds.to_i
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

  def create_queue(queue, dlq, options)
    sqs = AWS::SQS.new
    options = options.merge(redrive_policy: %Q{{"maxReceiveCount":"10", "deadLetterTargetArn":"#{dlq.arn}"}"})
    q_name = qn(queue)
    puts "create #{q_name}: #{options.inspect}"
    sqs.queues.create(q_name, options)
  end

  def create_dlq(queue, options)
    sqs = AWS::SQS.new
    dlq_name = "#{qn(queue)}_failures"
    puts "create DLQ #{dlq_name}: #{options.inspect}"
    sqs.queues.create(dlq_name, options)
  end

  def qn(n)
    "#{SystemInformation.env}_#{n}"
  end
end
