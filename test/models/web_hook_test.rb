require 'test_helper'

class WebHookTest < ActiveSupport::TestCase

  let(:job) { Job.create(job_type: 'audio', application_id: 1, original: "file://#{in_file('test_long.wav')}") }
  let(:task) do
    job.tasks.create!(task_type: 'transcode',
                      label: 'test',
                      options: { format: 'mp3', sample_rate: '44100', bit_rate: '128' },
                      result: "file://#{out_file('test_long.mp3')}",
                      call_back: 'http://localhost/audio/transcoded').tap { |t|
                        t.handle_status_changes
                      }
  end

  let(:web_hook) do
    task.result_task_log.create_web_hook( url: 'http://localhost/audio/transcoded',
                                          message: task.to_call_back_message)
  end

  it 'belongs to a task log' do
    web_hook.informer.wont_be_nil
  end

  it 'can be completed' do
    web_hook.wont_be :completed?
    web_hook.update_completed(true)
    web_hook.must_be :completed?
  end

  it 'can be scheduled for retry' do
    web_hook.scheduled_jobs.count.must_equal 0
    web_hook.retry_max = 1
    web_hook.update_completed(false)
    web_hook.wont_be :completed?
    web_hook.scheduled_jobs.count.must_equal 1
  end

  it 'wont be scheduled for retry if max is less than count' do
    web_hook.scheduled_jobs.count.must_equal 0
    web_hook.retry_max = 0
    web_hook.update_completed(false)
    web_hook.wont_be :completed?
    web_hook.scheduled_jobs.count.must_equal 0
  end

  it 'calculates an exponential retry delay' do
    web_hook.retry_count.must_equal 0
    web_hook.calculate_retry_delay.must_equal 10.minutes

    web_hook.retry_count = 1
    web_hook.calculate_retry_delay.must_equal 20.minutes

    web_hook.retry_count = 2
    web_hook.calculate_retry_delay.must_equal 40.minutes
  end

  it 'has a max exponential retry delay' do
    web_hook.retry_count = 100
    web_hook.calculate_retry_delay.must_equal 7.days
  end

  it 'sends the webhook message' do
    web_hook.process_web_hook.must_equal true
    web_hook.call_web_hook
    web_hook.process_web_hook.must_equal false
  end

  it 'gets the inform status' do
    web_hook.informer_status.must_equal task.status
  end

  it 'becomes a message with status' do
    web_hook.to_message['web_hook']['informer_status'].must_equal task.status
  end
end
