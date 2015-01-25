# encoding: utf-8

require 'service_options'

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

  def ended?
    error? || complete?
  end

  def success?
    complete?
  end

  def sequenced?
    !sequence_id.nil?
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
    @result_log ||= task_logs.where(status: status).order('created_at ASC').last
  end

  def to_message
    self.to_json(include: :job)
  end
end
