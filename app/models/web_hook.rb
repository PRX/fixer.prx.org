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
      update_attribute(:completed_at, nil)
      delay = (2**(retry_count + 1)/2) * 10.minutes
      schedule_in(delay.seconds, { method: :scheduled_retry }) if !retry_scheduled?
    end
  end

  def scheduled_retry(data={})
    return if completed?
    process_web_hook = true
    update_attribute(:retry_count, (retry_count + 1))
  end

  def call_web_hook
    send_webook_message if process_web_hook
  end

  def informer_status
    informer.try(:status)
  end

  def to_message
    self.as_json(methods: :informer_status)
  end

  def send_webook_message
    destination = :fixer_p2
    message = self.to_message
    logger.debug "publish message to do web_hook: #{destination} : #{message}"
    WebHookWorker.publish(destination, message)
  end
end
