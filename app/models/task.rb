# encoding: utf-8

class Task < BaseModel
  enum status: STATUS_VALUES

  belongs_to :job, autosave: true

  belongs_to :sequence, autosave: true

  has_many :task_logs

  serialize :options

  acts_as_list scope: :sequence

  attr_accessor :process_task, :previous_status

  validates_presence_of :job_id, unless: :sequenced?

  before_validation(on: :create) do
    self.status = CREATED
    self.process_task = true
  end

  def sequenced?
    !sequence_id.nil?
  end
end
