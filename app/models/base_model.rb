# encoding: utf-8

require 'fixer_constants'

class BaseModel < ActiveRecord::Base

  self.include_root_in_json = true
  self.abstract_class = true

  include FixerConstants

  acts_as_scheduled

  def retry_scheduled?
    scheduled_jobs.
      where(job_method: 'scheduled_retry').
      where('status != ?', COMPLETE).
      exists?
  end
end
