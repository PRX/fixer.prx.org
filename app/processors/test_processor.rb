# encoding: utf-8

require 'base_processor'

class TestProcessor < BaseProcessor

  task_types ['echo']

  def echo_test
    sleep(1) # pretend to do some work here
    completed_with message
  end
end
