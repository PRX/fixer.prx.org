# encoding: utf-8

class Job < BaseModel
  enum status: STATUS_VALUES

  JOB_TYPES = ['audio', 'image', 'file', 'text']

  has_many :tasks
  has_one :web_hook, as: :informer

  serialize :original

  before_validation(on: :create) { self.status = CREATED }

  validates_presence_of :job_type, :status, :client_application_id
  validates_inclusion_of :job_type, in: JOB_TYPES

  scope :incomplete, -> { where(status: [CREATED, ERROR]) }
  scope :failed, -> { where(status: ERROR) }

  def ended?
    tasks(true).all?{|t| t.ended?}
  end

  def success?
    tasks(true).all?{|t| t.success?}
  end

  def retry?
    retry_count < retry_max
  end

  def task_ended(task)
    return if cancelled?
    logger.debug "job: task_ended: start"
    if ended?
      logger.debug "job: task_ended: all ended"
      success? ? complete! : error!
      send_call_back
      retry_on_error
    else
      logger.debug "job: task_ended: NOT all ended: " + tasks.collect{|t| "#{t.id}:#{t.status}"}.join(', ')
    end
  end

  def send_call_back(force=false)
    self.web_hook = nil if force
    return if (call_back.blank? || web_hook)
    create_web_hook(url: call_back, message: to_call_back_message)
  end

  def retry_on_error
    return if (success? || cancelled? || !retry? || retry_scheduled?)
    # temporary

    # consider this for exponential retry
    # delay = (2**(retry_count)/2) * retry_delay.seconds
    # schedule_in(delay.seconds, {:method=>:scheduled_retry})

    # this is the current job
    # schedule_in(retry_delay.seconds, {:method=>:scheduled_retry})
  end

  def retry_scheduled?
    true # temporary
  #   scheduled_jobs.
  #     where(job_method: "scheduled_retry").
  #     where('next_fire_at > ?', Time.now).
  #     where('status != "complete"').exists?
  # rescue
  #   false
  end

  def scheduled_retry(data={})
    self.retry(false)
  end

  def retry(force=false)
    return if (!force && (success? || cancelled? || !retry?))

    # remove old webhook so new one can be created
    self.web_hook = nil

    self.update_attributes(status:      RETRYING,
                           retry_count: (retry_count+1),
                           retry_max:   [(retry_count+1), retry_max].max)

    tasks.each{|t| t.retry_task(force)}
  end

  def to_call_back_message
    to_json(
      only: [:id, :job_type, :original, :status],
      include: {
        tasks: {
          only: [:id, :task_type, :result, :label, :options, :call_back],
          methods: :result_details
        }
      }
    )
  end

  def self.create_from_message(h, client=nil)
    raise 'Message must specify job' unless h['job']

    tasks = h['job'].delete('tasks') || []
    job = Job.new(h['job'])

    raise 'Jobs must have at least one task' unless tasks && tasks.size > 0

    begin
      Job.transaction do
        job.save!
        tasks.each do |t|
          if t.keys.first == 'task'
            job.tasks.create!(t['task'])
          elsif t.keys.first == 'sequence'
            sequence_tasks = t['sequence'].delete('tasks') || []
            sequence = Sequence.new(t['sequence'])
            job.tasks << sequence
            sequence.save!
            sequence_tasks.each { |st| sequence.tasks.create!(st['task']) }
          end
        end
      end
    rescue
      logger.error("Failed to create new job and tasks: #{$!.message}\n\t#{$!.backtrace.join("\n\t")}")
      raise $!
    end
  end
end
