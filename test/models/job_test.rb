require 'test_helper'

class JobTest < ActiveSupport::TestCase

  let(:job) { Job.create(job_type: 'audio', priority: 1, application_id: 1) }

  it 'uses uuid for id' do
    job.must_be :valid?
  end

  it 'defaults status enum to created' do
    job.must_be :created?
  end

  it 'should have a priority' do
    job.priority.must_equal 1
  end

  it 'is not ended when all tasks succeed or fail' do
    job.must_be :ended?

    t1 = job.tasks.create!(task_type: 'audio', label: 'test1')
    t2 = job.tasks.create!(task_type: 'audio', label: 'test2')
    job.wont_be :ended?

    t1.complete!
    t2.error!
    job.must_be :ended?
  end

  it 'is a success when all task succeed' do
    (0..3).each {
      job.tasks.create!(task_type: 'audio', label: 'test1').complete!
    }
    job.must_be :success?
  end

  it 'is cancelled when marked cancelled' do
    job.cancelled!
    job.must_be :cancelled?
  end

  it 'can be in a callback message' do
    msg = JSON.parse(job.to_call_back_message)
    msg['job'].wont_be_nil
    msg['job']['status'].must_equal 'created'
  end

  it 'calculates an exponential retry delay' do
    job.retry_delay = 10.minutes
    job.retry_count = 0
    job.calculate_retry_delay.must_equal 10.minutes

    job.retry_count = 1
    job.calculate_retry_delay.must_equal 20.minutes

    job.retry_count = 2
    job.calculate_retry_delay.must_equal 40.minutes
  end

  it 'has a max exponential retry delay' do
    job.retry_delay = 10.minutes
    job.retry_count = 100
    job.calculate_retry_delay.must_equal 7.days
  end

  describe 'task updates' do

    let(:task) { job.tasks.create!(task_type: 'audio', label: 'test1')}

    it 'will update when task ended' do
      task.error!
      job.must_be :created?
      job.task_ended(task)
      job.must_be :error?
    end
  end

  describe 'create from message' do
    let(:user) { User.create!(email: 'test@prx.org', password: 'foobarpassword') }
    let(:application) { Doorkeeper::Application.create(name: 'test', owner: user, redirect_uri: 'urn:ietf:wg:oauth:2.0:oob') }

    it 'creates from a message with one task' do
      hash = {
        job_type: 'test',
        priority: 1,
        retry_max: 10,
        retry_delay: 300,
        tasks: [
          {
            task_type: 'echo',
            label: 'test1',
            options: { foo: 'bar' },
            call_back: 'http://cms.prx.dev/call_back'
          }
        ]
      }.with_indifferent_access
      job = Job.create_from_message(hash, application)
      job.must_be :valid?
      job.must_be :persisted?
      job.tasks.size.must_equal 1
      job.job_type.must_equal 'test'
      job.priority.must_equal 1
      job.retry_max.must_equal 10
      job.retry_delay.must_equal 300
    end

    it 'creates from a message with a sequence' do
      hash = {
        job_type: 'test',
        priority: 1,
        retry_max: 10,
        retry_delay: 300,
        tasks: [
          sequence: {
            tasks: [
              {
                task_type: 'echo',
                label: 'test1',
                options: { foo: 'bar' },
                call_back: 'http://cms.prx.dev/call_back'
              },
              {
                task_type: 'echo',
                label: 'test1',
                options: { bar: 'foo' },
                call_back: 'http://cms.prx.dev/call_back'
              }
            ]
          }
        ]
      }.with_indifferent_access

      job = Job.create_from_message(hash, application)
      job.must_be :valid?
      job.must_be :persisted?
      job.tasks.size.must_equal 1
      job.tasks.first.must_be_instance_of Sequence
      job.tasks.first.tasks.size.must_equal 2
    end
  end
end
