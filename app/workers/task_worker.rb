# encoding: utf-8

require 'base_worker'

class TaskWorker < BaseWorker

  queue_as { destination_symbol(self.arguments.first) }

  def destination_symbol(task)
    priority = task['job']['priority']
    priority = priority.blank? ? DEFAULT_PRIORITY : [priority.to_i, MAX_PRIORITY].min
    "fixer_p#{priority}".to_sym
  end

  def perform(msg)
    task = JSON.parse(msg).with_indifferent_access
    logger.info("TaskWorker: task: #{task.inspect}")
    job_type = extract_job_type(task)
    processor = lookup_processor(job_type)
    processor.on_message(task)
  end

  def extract_job_type(task)
    t = task['task'] || task['sequence']
    jt = t['job']['job_type']
    raise "Unrecognized job type: #{jt}" unless JOB_TYPES.include?(jt.to_s)
    jt
  end

  def lookup_processor(job_type)
    processor_name = "#{job_type}_processor"
    processor_class = processor_name.classify.constantize
    processor_class.new(logger: logger)
  end
end
