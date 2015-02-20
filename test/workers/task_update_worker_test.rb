require 'test_helper'

class TaskUpdateWorkerTest < ActiveSupport::TestCase

  before {
    ENV['WORKER_LIB'] = 'local'
  }

  let(:job) { Job.create!(job_type: 'audio', priority: 1, application_id: 1) }
  let(:task) { Task.create!(job: job) }

  let(:msg) do
    l = {
      task_log: {
        logged_at: Time.now,
        task_id: task.id,
        status: 'processing',
        message: 'Processing started!',
        info: {
          started_at: Time.now
        },
      }
    }
    JSON.parse(l.to_json)
  end

  it 'calls worker perform' do
    log = TaskUpdateWorker.publish('test-queue', msg)
    log.must_be_instance_of TaskLog
    log.task_id.must_equal task.id
    log.status.must_equal 'processing'
  end
end
