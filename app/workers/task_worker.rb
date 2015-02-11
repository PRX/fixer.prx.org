# encoding: utf-8

require 'base_worker'

class TaskWorker < BaseWorker

  def perform(task)
    job_type = extract_job_type(task)
    processor = lookup_processor(job_type)
    processor.on_message(task)
  end

  def extract_job_type(task)
    # identify the type of job
    t = task['task'] || task['sequence']
    jt = j['job']['job_type']

    raise "Unrecognized job type: #{jt}" unless JOB_TYPES.include?(jt.to_sym)

    jt
  end

  def lookup_processor(job_type)
    processor_name = "#{job_type}_processor"
    # require processor_name # is this necessary?
    processor_class = processor_name.classify.constantize
    processor_class.new(logger: logger)
  end
end
