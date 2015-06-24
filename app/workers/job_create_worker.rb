# encoding: utf-8

require 'fixer_constants'
require 'system_information'
require 'service_options'

class JobCreateWorker

  include FixerConstants
  include Shoryuken::Worker

  shoryuken_options queue: "#{SystemInformation.env}_fixer_job_create"

  def perform(sqs_msg, body)
    ActiveRecord::Base.connection_pool.with_connection do
      job = body.with_indifferent_access
      job = job[:job] if job[:job]
      client_id = job.delete(:client_id)
      application = Doorkeeper::Application.where(uid: client_id).first
      Job.create_from_message(job, application)
    end
  end
end
