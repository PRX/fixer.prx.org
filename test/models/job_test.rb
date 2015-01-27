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

  describe 'task updates' do

    let(:task) { job.tasks.create!(task_type: 'audio', label: 'test1')}

    it 'will update when task ended' do
      task.error!
      job.must_be :created?
      job.task_ended(task)
      job.must_be :error?
    end

  end

end
