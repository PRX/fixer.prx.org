require 'test_helper'

class WebHookWorkerTest < ActiveSupport::TestCase

  before {
    WebMock.disable_net_connect!
  }

  after {
    WebMock.allow_net_connect!
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

  let(:worker) { WebHookWorker.new }
  let(:msg) { web_hook.to_message.to_json }

  it 'calls worker perform' do
    stub_request(:post, 'http://localhost/audio/transcoded').
      to_return(status: 200, body: "", headers: {})

    log = worker.perform(msg)
    log[:web_hook][:complete].must_equal true
  end

  it 'schedules retry on failure' do
    stub_request(:post, 'http://localhost/audio/transcoded').
      to_return(status: 500, body: 'error will robinson', headers: {})

    log = worker.perform(msg)
    log[:web_hook][:complete].must_equal false
  end

  it 'can make an http call' do

    stub_request(:post, 'http://localhost/audio/transcoded').
      to_return(:status => 200, :body => "", :headers => {})

    worker.http_execute('http://localhost/audio/transcoded', '{"some":"message"}')
  end

  it 'gets mime from content type' do
    worker.mime_type_string(:json).must_equal 'application/json; charset=utf-8'
  end
end
