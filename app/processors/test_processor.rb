# encoding: utf-8

class TestProcessor < BaseProcessor

  task_types ['echo']

  def echo_test
    completed_with message
  end
end
