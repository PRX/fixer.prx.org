require 'test_helper'

class TaskTest < ActiveSupport::TestCase

  let(:job) { Job.create(job_type: 'audio', application_id: 1, original: "file://#{in_file('test_long.wav')}") }
  let(:task) { job.tasks.create!( task_type: 'transcode',
                                  label: 'test',
                                  options: { format: 'mp3', sample_rate: '44100', bit_rate: '128' },
                                  result: "file://#{out_file('test_long.mp3')}",
                                  call_back: 'http://localhost/audio/transcoded') }

  it 'uses uuid for id' do
    task.must_be :valid?
    task.id.length.must_equal 36
  end

  it 'uses an enum for the status' do
    task.must_be :created?
  end

  it "belongs to a job" do
    task.job.must_equal job
  end

  it "should not be ended on create" do
    task.wont_be :ended?
    task.wont_be :success?
    task.wont_be :error?
  end

  it "should not be success on complete" do
    task.complete!
    task.must_be :ended?
    task.must_be :success?
    task.wont_be :error?
  end

  it "should not be success on complete" do
    task.error!
    task.must_be :ended?
    task.wont_be :success?
    task.must_be :error?
  end

  it "should update status on error log" do
    task.wont_be :error?
    task.log(Task::ERROR, "message")
    task.must_be :error?
  end

  it "should keep status on info log" do
    before_status = task.status
    task.log(Task::INFO, "message")
    task.status.must_equal before_status
  end

  it "should become a json message" do
    task.to_call_back_message.wont_be_nil
  end

  it 'can find the last log' do
    task.must_be :created?
    task.result_task_log.must_be_nil
    task.process_task.must_equal true

    task.handle_status_changes
    task.result_task_log.wont_be_nil
  end

  it 'log can update the status' do
    task.handle_status_changes
    log = task.log(Task::PROCESSING, "started processing")
    task.handle_status_changes
    task.result_task_log.must_equal log
  end

  it 'log updates the status and sends callbacks' do
    logs = {}

    # created
    task.call_back.wont_be_nil
    task.result_task_log.must_be_nil

    # created after_commit
    task.handle_status_changes
    logs['created'] = task.result_task_log
    logs['created'].web_hook.wont_be_nil

    ['processing', 'complete'].each do |new_state|
      logs[new_state] = task.log(new_state, "#{new_state} status")
      logs[new_state].web_hook.must_be_nil

      # after_commit
      task.handle_status_changes
      logs[new_state].web_hook(true).wont_be_nil
    end

    logs.each { |k,l| l.status.must_equal k }
  end

  it 'publishes task message' do
    task.process_task.must_equal true
    task.publish_messages
    task.process_task.must_equal false
  end
end
