require 'test_helper'

class WebHookUpdateWorkerTest < ActiveSupport::TestCase

  before {
    ENV['WORKER_LIB'] = 'inline'
    ActiveJob::Base.queue_adapter = :inline
  }

  after {
    ENV['WORKER_LIB'] = 'test'
    ActiveJob::Base.queue_adapter = :test
  }

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

  let(:msg) do
    {
      web_hook: {
        id: web_hook.id,
        complete: true
      }
    }.to_json
  end

  it 'calls worker perform' do
    web_hook.completed_at.must_be_nil
    web_hook = WebHookUpdateWorker.new.perform(msg)
    web_hook.completed_at.wont_be_nil
  end
end
