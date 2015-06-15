# encoding: utf-8

require 'base_worker'

class JobCreateWorker < BaseWorker

  queue_as :fixer_job

  def perform(msg)
    ActiveRecord::Base.connection_pool.with_connection do
      job = JSON.parse(msg).with_indifferent_access
      application_id = job.delete(:application_id)
      application = Doorkeeper::Application.find(application_id)
      Job.create_from_message(job, application)
    end
  end
end
