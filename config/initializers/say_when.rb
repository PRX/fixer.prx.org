require 'say_when'

# we're gonna run this so it has it's own STDOUT logging
SayWhen.logger = Logger.new(STDOUT)
SayWhen.logger.level = Rails.logger.level

SayWhen::Scheduler.configure do |scheduler|
  scheduler.storage_strategy = :active_record
  scheduler.processor_class  = SayWhen::Processor::Simple
end
