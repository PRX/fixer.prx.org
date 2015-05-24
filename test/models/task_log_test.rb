require 'test_helper'

class TaskLogTest < ActiveSupport::TestCase

  let(:job) { Job.create!(job_type: 'test', priority: 1, application_id: 1) }
  let(:task) { Task.create!(job: job) }
  let(:task_log) { task.log(Task::INFO, "this is a test", { foo: 1, bar: 2 } ) }

  it 'has a status and message' do
    task_log.status.must_equal 'info'
    task_log.message.must_equal 'this is a test'
  end

  it 'must have a status' do
    task_log.status = nil
    task_log.wont_be :valid?
  end

  it 'must have a message' do
    task_log.message = nil
    task_log.wont_be :valid?
  end

  it 'can have a webhook' do
    web_hook = task_log.create_web_hook(url: task.call_back, message: 'this is a test message', retry_max: 1)
    web_hook.wont_be_nil
  end

  it 'serializes info' do
    task_log.info.must_equal({ foo: 1, bar: 2 })
  end

  it 'belongs to a task' do
    task_log.task.must_equal task
  end
end
