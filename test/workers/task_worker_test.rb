require 'test_helper'

class TaskWorkerTest < ActiveSupport::TestCase

  before {
    ENV['WORKER_LIB'] = 'local'
  }

  let(:job) { Job.create!(job_type: 'test', priority: 1, application_id: 1) }
  let(:task) { Task.create!(job: job, task_type: 'echo', options: { foo: 'bar' } ) }

  let(:msg) { JSON.parse(task.to_message.to_json) }

  let(:worker) { TaskWorker.new }

  it 'calls worker perform' do
    results = worker.perform(msg)
    results[:status].must_equal :complete
    results[:message].must_equal "Echo test complete."
    results[:info]['task']['id'].must_equal task.id
  end
end
