# encoding: utf-8

require 'fixer_constants'
require 'system_information'
require 'service_options'

class CustomBaseWorker
  include FixerConstants

  def self.worker_lib
    ENV['WORKER_LIB'] || 'local'
  end

  require "#{worker_lib}_worker"
  include "#{worker_lib}_worker".classify.constantize
end
