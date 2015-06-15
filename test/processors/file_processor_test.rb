require 'test_helper'

class FileProcessorTest < ActiveSupport::TestCase
  let(:processor) { FileProcessor.new(logger: Logger.new('/dev/null')) }

  it 'defines supported tasks' do
    FileProcessor.supported_tasks.first.must_equal 'copy'
  end

  describe 'copy_file' do

    let(:msg) {
      {
        task: {
          id: 'guid1',
          task_type: 'copy',
          label: 'xerox',
          job: { id: 'guid1', job_type: 'file', status: 'created', original: "file://#{in_file('test_long.wav')}" },
          options: {},
          result: 'file:///test/files/copy_test_long.wav'
        }
      }.with_indifferent_access
    }

    it 'should copy file' do
      processor.on_message(msg)
      processor.result_details[:info][:format].must_equal 'wav'
    end
  end
end
