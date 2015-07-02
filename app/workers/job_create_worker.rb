# encoding: utf-8

require 'custom_base_worker'

class JobCreateWorker < CustomBaseWorker

  worker_options queue: "#{SystemInformation.env}_fixer_job_create"

  def process(body)
    ActiveRecord::Base.connection_pool.with_connection do
      body = JSON.parse(body) if body.is_a?(String)
      job = body.with_indifferent_access
      job = job[:job] if job[:job]
      client_id = job.delete(:client_id)
      application = Doorkeeper::Application.where(uid: client_id).first
      Job.create_from_message(job, application)
    end
  end
end
