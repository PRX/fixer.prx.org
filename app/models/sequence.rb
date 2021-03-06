# encoding: utf-8

# Sequence is a subclass of task that has an ordered list of tasks, and does them all as one task
# if it errors out, retries the whole sequence
class Sequence < Task
  has_many :tasks, -> { order("position ASC") }

  def task_type
    'sequence'
  end

  def task_type=(tt)
    # noop
  end

  def task_ended(task)
    if success?
      log(COMPLETE, 'Sequence tasks completed.')
    elsif error?
      log(ERROR, 'Sequence task failed!')
    end
  end

  def ended?
    error? || success?
  end

  def error?
    tasks.any?{|t| t.error?}
  end

  def success?
    tasks.all?{|t| t.success?}
  end

  def to_call_back_message
    as_json(
      only: [:id, :task_type, :result, :label, :options, :call_back],
      methods: :result_details,
      include: {
        tasks: {
          only: [:id, :task_type, :result, :label, :options, :call_back],
          methods: :result_details
        },
        job: {
          only: [:id, :job_type, :original, :status]
        }
      }
    )
  end

  def to_message
    self.as_json(include: [:job, :tasks])
  end
end
