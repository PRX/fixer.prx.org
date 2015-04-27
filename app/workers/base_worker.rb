# encoding: utf-8

require 'active_job'
require 'fixer_constants'
require 'system_information'
require 'service_options'

class BaseWorker < ActiveJob::Base
  include FixerConstants

  def self.worker_lib
    ENV['WORKER_LIB'] || 'inline'
  end
end
