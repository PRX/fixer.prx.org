require 'test_helper'

class JobCreateWorkerTest < ActiveSupport::TestCase

  before {
    ENV['WORKER_LIB'] = 'inline'
    ActiveJob::Base.queue_adapter = :inline
  }

  after {
    ENV['WORKER_LIB'] = 'test'
    ActiveJob::Base.queue_adapter = :test
  }


  let(:user) { User.create!(email: 'test@prx.org', password: 'foobarpassword') }

  let(:application) do
    Doorkeeper::Application.create(
      name: 'test',
      owner: user,
      redirect_uri: 'urn:ietf:wg:oauth:2.0:oob'
    )
  end

  let(:msg) do
    {
      client_id: application.uid,
      job_type: 'test',
      priority: 1,
      retry_max: 10,
      retry_delay: 300,
      tasks: [
        {
          task_type: 'echo',
          label: 'test0',
          options: { foo: 'bar' },
          call_back: 'sqs://prx-some-app'
        }
      ]
    }
  end

  let(:sequence_msg) do
    {
      client_id: application.uid,
      job_type: 'test',
      priority: 1,
      retry_max: 10,
      retry_delay: 300,
      tasks: [
        sequence: {
          tasks: [
            {
              task_type: 'echo',
              label: 'test0',
              options: { foo: 'bar' },
              call_back: 'sqs://prx-some-app'
            },
            {
              task_type: 'echo',
              label: 'test1',
              options: { foo: 'bar' },
              call_back: 'sqs://prx-some-app'
            }
          ]
        }
      ]
    }
  end

  let(:sqs_message) { Minitest::Mock.new }

  it 'creates a job from a message' do
    job = JobCreateWorker.new.perform(sqs_message, msg)
    job.wont_be_nil
    job.id.wont_be_nil
    job.tasks.size.must_equal 1
  end

  it 'creates a job from a message with a uuid' do
    msg[:id] = '3a38f72f-8ef9-40c1-8d1c-484c93d97e97'
    job = JobCreateWorker.new.perform(sqs_message, msg)
    job.id.must_equal '3a38f72f-8ef9-40c1-8d1c-484c93d97e97'
  end

  it 'creates a job from a message with a sequence' do
    job = JobCreateWorker.new.perform(sqs_message, sequence_msg)
    job.tasks.first.tasks.size.must_equal 2
  end
end
