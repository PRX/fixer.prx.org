# encoding: utf-8

class BaseModel < ActiveRecord::Base

  self.include_root_in_json = true
  self.abstract_class = true

  include FixerConstants

  acts_as_scheduled

  def retry_scheduled?
    scheduled_jobs.
      where(job_method: 'scheduled_retry').
      where('next_fire_at > ?', Time.now).
      where('status != "complete"').exists?
  rescue
    false
  end
end
