# encoding: utf-8

require 'base_worker'

class TaskWorker < BaseWorker

  def process(task)
    logger.debug("TaskWorker: task: #{task.inspect}")
    task = task.with_indifferent_access
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
