# encoding: utf-8

class WebHook < BaseModel
  attr_accessor :process_web_hook

  # acts_as_scheduled

  belongs_to :informer, :polymorphic => true

  before_validation(on: :create) do
    self.process_web_hook = true
    self.retry_max = 5 unless retry_max_changed?
  end

  after_commit :call_web_hook, if: :persisted?

  validates_presence_of :url, :message

  def completed?
    !completed_at.nil?
  end

  def update_completed(complete)
    if complete
      update_attribute(:completed_at, Time.now)
    elsif retry_count < retry_max
      delay = (2**(retry_count + 1)/2) * 10.minutes
      # schedule_in(delay.seconds, { method: :scheduled_retry }) if !retry_scheduled?
    end
  end

  # def retry_scheduled?
  #   scheduled_jobs.
  #     where(job_method: "scheduled_retry").
  #     where('next_fire_at > ?', Time.now).
  #     where('status != "complete"').exists?
  # rescue
  #   false
  # end

  def scheduled_retry(data={})
    return if completed?
    process_web_hook = true
    update_attribute(:retry_count, (retry_count + 1))
  end

  def call_web_hook
    publish :web_hooks, self.to_message if process_web_hook
  end

  def to_message
    self.as_json(include: :informer, except: [:informer_id, :informer_type])
  end

end
