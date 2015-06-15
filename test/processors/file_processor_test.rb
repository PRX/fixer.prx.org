require 'test_helper'

class FileProcessorTest < ActiveSupport::TestCase

  let(:audio_monster) do
    Minitest::Mock.new
  end

  let(:processor) do
    FileProcessor.new(logger: Logger.new('/dev/null')).tap do |p|
      p.audio_monster = audio_monster if travis?
    end
  end

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
      if travis?
        audio_monster.expect(:info_for, { format: 'wav' }, [String])
        audio_monster.expect(:info_for, { format: 'wav' }, [String])
        audio_monster.expect(:info_for, { format: 'wav' }, [String])
      end

      processor.on_message(msg)
      processor.result_details[:info][:format].must_equal 'wav'
    end
  end
end
