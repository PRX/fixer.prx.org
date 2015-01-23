# encoding: utf-8

class Job < BaseModel
  enum status: STATUS_VALUES

  JOB_TYPES = ['audio', 'image', 'file', 'text']

  has_many :tasks, autosave: true
  has_one :web_hook, as: :informer

  serialize :original

  before_validation(on: :create) { self.status = CREATED }

  validates_presence_of :job_type, :status, :client_application_id
  validates_inclusion_of :job_type, in: JOB_TYPES

  scope :incomplete, -> { where(:status => [CREATED, ERROR]) }
  scope :failed, -> { where(:status => ERROR) }

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
