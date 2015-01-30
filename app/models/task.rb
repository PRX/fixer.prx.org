# encoding: utf-8

class Task < BaseModel
  enum status: STATUS_VALUES

  belongs_to :job

  belongs_to :sequence

  has_many :task_logs

  serialize :options

  acts_as_list scope: :sequence

  attr_accessor :process_task, :previous_status

  validates_presence_of :job_id, unless: :sequenced?

  before_validation(on: :create) do
    self.status = CREATED
    self.process_task = true
  end

  after_commit :publish_messages, if: :persisted?

  after_commit :handle_status_changes, if: :persisted?

  def ended?
    error? || complete?
  end

  def success?
    complete?
  end

  def sequenced?
    !sequence_id.nil?
  end

  def log(state, message, info=nil, logged_at=Time.now)
    info ||= {}
    task_log = nil

    # changes attributes lost to after commit hook
    self.previous_status = self.status

    logger.info "Task.log: #{self.id} : #{state} : #{message} : #{info.inspect[0,100]}"

    Task.transaction do
      task_log = task_logs.create(status: state, message: message, info: info, logged_at: logged_at)
      update_status(state, message, info, logged_at)
    end

    task_log
  end

  def update_status(state, message, info, logged_at)
    # TODO: introduce lock on the task so this prevents concurrent updates messing up

    # if this is not a status that updates (such as info), then skip it
    return unless STATUS_VALUES.include?(state)

    # see if there is already another status that came in that was logged_at > than this one.
    future_log = task_logs.where('logged_at > ? and status in (?)', logged_at, STATUS_VALUES)
    update_attribute(:status, state) unless future_log
  end

  def retry_task(force=false)
    return if (!force && success?)

    # setting this causes this post commit callback to send out the message
    self.process_task = true

    task_log = task_logs.create(status: RETRYING, message: "retrying task: status: #{status}, force: #{force}", logged_at: Time.now)
    self.update_attributes(status: RETRYING)
    task_log
  end

  def handle_status_changes
    return if previous_status == status

    logger.debug "task: publish_messages: #{previous_status} != #{status}"

     if process_task && status == CREATED
      # log create on after_commit
      task_logs.create(status: CREATED, message: 'created message.', logged_at: Time.now)
    end

    logger.debug "task: publish_messages: send_call_back: #{status}"
    send_call_back

    # if the task has ended, let the job or sequece know so it can do a callback
    job.task_ended(self) if (ended? && job)
    sequence.task_ended(self) if (ended? && sequence)
  end

  def publish_messages
    # if need to process a task, send the message for that last of all
    send_task_message if (process_task && sequence_id.nil?)
  end

  # def send_task_message
  #   destination = destination_symbol
  #   message = self.to_message
  #   logger.debug "publish message to do task: #{destination} : #{message}"

  #   publish(destination, message)
  # end

  # def destination_symbol
  #   priority = if job.priority.blank?
  #     MediaMonster.destination_priorities.last
  #   else
  #     # this is for backwards compatibility
  #     if job.priority.to_s == 'high'
  #       1
  #     else
  #       job.priority.to_i
  #     end
  #   end

  #   # priority limited by what queues exist, defulat to lowest priority if bad one specified
  #   priority = MediaMonster.destination_priorities.last unless MediaMonster.destination_priorities.include?(priority)

  #   "#{job.job_type}_priority_#{priority}".to_sym
  # end

  def send_call_back(force=true)
    rtl = result_task_log
    rtl.web_hook = nil if force

    return if (call_back.blank? || rtl.web_hook)
    rtl.create_web_hook(url: call_back, message: to_call_back_message)
  end

  def to_call_back_message
    to_json(
      only: [:id, :task_type, :result, :label, :options, :call_back],
      methods: :result_details,
      include: {
        job: {
          only: [:id, :job_type, :original, :status]
        }
      }
    )
  end

  def result_details
    rtl = result_task_log
    {
      status:    rtl.status,
      message:   rtl.message,
      info:      rtl.info,
      logged_at: rtl.logged_at
    } if rtl
  end

  def result_task_log
    task_logs.where(status: status).order('logged_at ASC').last
  end

  def to_message
    self.to_json(include: :job)
  end
end
