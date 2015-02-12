require 'test_helper'

class AudioProcessorTest < ActiveSupport::TestCase

  let(:processor) { AudioProcessor.new(logger: Logger.new('/dev/null')) }

  it 'defines supported tasks' do
    AudioProcessor.supported_tasks.first.must_equal 'transcode'
  end

  it 'can symbolize hash' do
    processor.symbolize_options({'foo' => 'bar'})[:foo].must_equal 'bar'
  end

  describe 'slice_audio' do

    let(:msg) {
      {
        task: {
          id: 'guid1',
          task_type: 'slice',
          label: 'cuisanart',
          job: { id: 'guid2', job_type: 'audio', status: 'created', original: "file://#{in_file('test_long.wav')}" },
          options: { start: '10', length: '5' }
        }
      }.with_indifferent_access
    }

    it 'should return sliced duration' do
      processor.on_message(msg)
      processor.result_details[:info][:length].to_i.must_equal 5
    end
  end

  describe 'tone_detect_audio' do

    let(:msg) {
      {
        task: {
          id: 'guid3',
          task_type: 'tone_detect',
          label: 'tone_detect',
          job: { id: 1, job_type: 'audio', status: 'created', original: "file://#{in_file('test.flac')}" },
          options: { frequency: '25' }
        }
      }.with_indifferent_access
    }

    it 'should return one tone at 5-6 seconds' do
      processor.on_message(msg)

      # puts 'tones:'
      # processor.result_details[:info].each{|t| puts "#{t[:start].to_i.to_time_string_summary} - #{t[:finish].to_i.to_time_string_summary}" }

      # puts processor.result_details.inspect
      processor.result_details[:info].size.must_equal 1
      processor.result_details[:info].first[0].to_i.must_equal 5
      processor.result_details[:info].first[1].to_i.must_equal 6
    end

  end

end
