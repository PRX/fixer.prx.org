require 'test_helper'

class AudioProcessorTest < ActiveSupport::TestCase

  before {
    WebMock.disable_net_connect!
  }

  after {
    WebMock.allow_net_connect!
  }

  let(:processor) { AudioProcessor.new(logger: Logger.new('/dev/null')) }

  it 'defines supported tasks' do
    AudioProcessor.supported_tasks.first.must_equal 'transcode'
  end

  it 'can symbolize hash' do
    processor.symbolize_options({'foo' => 'bar'})[:foo].must_equal 'bar'
  end

  describe 'analyze_audio' do

    let(:msg) {
      {
        task: {
          id: 'guid1',
          task_type: 'analyze',
          label: 'scope',
          job: { id: 'guid3', job_type: 'audio', status: 'created', original: "file://#{in_file('test_long.wav')}" },
          options: { start: '10', length: '5' }
        }
      }.with_indifferent_access
    }

    it 'should return analysis with loudness' do
      processor.on_message(msg)
      processor.result_details[:info][:length].to_i.must_equal 48
      processor.result_details[:info][:loudness][:integrated_loudness][:i].must_equal -18.5
    end
  end

  describe 'slice_audio' do

    let(:msg) {
      {
        task: {
          id: 'guid2',
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

  describe 'silence_detect_audio' do

    let(:msg) {
      {
        task: {
          id: 'guid4',
          task_type: 'silence_detect',
          label: 'silence_detect',
          job: { id: 1, job_type: 'audio', status: 'created', original: "file://#{in_file('test.flac')}" },
          options: {}
        }
      }.with_indifferent_access
    }

    it "should return one silence period, from 6-15" do
      processor.on_message(msg)

      # processor.result_details[:info].each{|t| puts "#{t[:start].to_i.to_time_string_summary} - #{t[:finish].to_i.to_time_string_summary}" }
      # puts "silence:"
      # puts "#{processor.result_details[:info].inspect}"

      processor.result_details[:info].size.must_equal 1
      processor.result_details[:info].first[0].round.must_equal 6
      processor.result_details[:info].first[1].round.must_equal 15
    end

  end

  describe "wrap_audio" do

    let(:msg_options) do
      {
        title: 'REMIX Episode 1',
        artist: 'PRX REMIX',
        cut_id: '12345',
        start_at: DateTime.parse('2010-06-19T00:00:00-04:00'),
        end_at: DateTime.parse('2010-06-19T00:00:00-04:00') + 6.days,
        producer_app_id: 'PRX'
      }
    end

    let(:msg) {
      {
        task: {
          id: 'guid4',
          task_type: 'wrap',
          label: 'wrap',
          job: { id: 1, job_type: 'audio', status: 'created', original: "file:///#{in_file('test_short.mp2')}" },
          options: msg_options,
          result: 'file:///test.fixer.org/test_short_wrap.wav'
        }
      }.with_indifferent_access
    }

    it "should set destination format" do
      processor.on_message(msg)
      processor.destination.wont_be_nil
      processor.destination_format.must_equal 'wav'
    end

    it "should create a wave wrapped mp2" do
      result_file_path = out_file('fixer/test.fixer.org/test_short_wrap.wav')
      FileUtils.rm_f(result_file_path)
      processor.on_message(msg)
      File.exists?(result_file_path).must_equal true
      wave = NuWav::WaveFile.parse(result_file_path)

      wave.chunks[:cart].title.must_equal "REMIX Episode 1"
      wave.chunks[:cart].artist.must_equal "PRX REMIX"
      wave.chunks[:cart].cut_id.must_equal "12345"
      wave.chunks[:cart].start_date.must_equal "2010/06/19"
      wave.chunks[:cart].start_time.must_equal "00:00:00"
      wave.chunks[:cart].end_date.must_equal "2010/06/25"
      wave.chunks[:cart].end_time.must_equal "00:00:00"
      wave.chunks[:cart].producer_app_id.must_equal "PRX"
    end
  end

  describe "wave form json" do

    let(:msg) {
      {
        task: {
          id: 'guid4',
          task_type: 'waveformjson',
          label: 'waveformjson',
          job: { id: 1, job_type: 'audio', status: 'created', original: "file://#{in_file('test_short.mp2')}" },
          options: {}
        }
      }.with_indifferent_access
    }

    it "should generate waveform" do
      processor.on_message(msg)
      processor.destination.wont_be_nil
      processor.destination_format.must_equal 'json'
      processor.result_details[:info].keys.sort.must_equal [:data_count]
      processor.result_details[:message].wont_be :blank?
    end

    it "should use with per second option" do
      msg[:task][:options] = { width_per_second: 500 }
      processor.on_message(msg)
      processor.destination.wont_be_nil
      processor.destination_format.must_equal 'json'
      processor.result_details[:info].keys.sort.must_equal [:data_count]
      processor.result_details[:info][:data_count].must_be :>=, 2800
    end
  end

  describe 'transcribe_audio' do
    let(:msg) {
      {
        task: {
          id: 'guid3',
          task_type: 'transcribe',
          label: 's2t',
          job: { id: 'guid3', job_type: 'audio', status: 'created', original: "file://#{in_file('test_short.mp2')}" },
          options: {}
        }
      }.with_indifferent_access
    }

    it "should get json results" do

      stub_request(:post, "https://www.google.com/speech-api/v2/recognize?client=chrome&key=AIzaSyBOti4mM-6x9WDnZIjIeyEU21OpBXqWBgw&lang=en-us&output=json").
        with(:headers => { 'Content-Type'=>'audio/x-flac; rate=8000', 'Host'=>'www.google.com:443' } ).
        to_return(:status => 200, :body => "", :headers => {})

      processor.on_message(msg)
      processor.result_details[:info].keys.sort.must_equal [:average_confidence, :character_count, :word_count]
      processor.result_details[:message].wont_be_nil
    end
  end

  describe "transcode audio" do

    let(:msg) {
      {
        task: {
          id: 'guid6',
          task_type: 'transcode',
          label: 'transcode',
          job: { id: 'guid7', job_type: 'audio', status: 'created', original: "file://#{in_file('test_short.mp2')}" },
          options: { format: 'mp3', sample_rate: '44100', bit_rate: '128' },
          result: 'file:///test.fixer.org/test_short_test.mp3'
        }
      }.with_indifferent_access
    }

    it "should set destination format" do
      processor.on_message(msg)
      processor.destination.wont_be_nil
      processor.destination_format.must_equal 'mp3'
    end

    it "should write the result of the transcode" do
      result_file_path = out_file('fixer/test.fixer.org/test_short_test.mp3')
      FileUtils.rm_f(result_file_path)
      processor.on_message(msg)
      File.exists?(result_file_path).must_equal true
    end

    it "should unset original" do
      processor.on_message(msg)
      processor.source.must_be_nil
      processor.original.must_be_nil
    end

    it "should set return info for result" do
      processor.on_message(msg)
      processor.result_details[:info].delete(:loudness)
      processor.result_details.must_equal({
        status: :complete,
        info: {
          size: 90696,
          content_type: 'audio/mpeg',
          channel_mode: 'JStereo',
          bit_rate: 128,
          length: 5,
          sample_rate: 44100,
          version: 1,
          layer: 3
        },
        message: 'Transcode audio complete.'
      })
    end
  end

  describe "copy_audio" do
    let(:msg) {
      {
        task: {
          id: 'guid4',
          task_type: 'copy',
          label: 'copy',
          job: { id: 1, job_type: 'audio', status: 'created', original: "file:///#{in_file('test_short.mp2')}" },
          options: {},
          result: 'file:///test.fixer.org/test_short_copy.mp2'
        }
      }.with_indifferent_access
    }

    it "should set destination format" do
      processor.on_message(msg)
      processor.destination.wont_be_nil
      processor.destination_format.must_equal 'mp2'
    end

    it "should create a wave wrapped mp2" do
      result_file_path = out_file('fixer/test.fixer.org/test_short_copy.mp2')
      FileUtils.rm_f(result_file_path)
      processor.on_message(msg)
      File.exists?(result_file_path).must_equal true
    end
  end

  describe "validate_audio" do

    let (:msg_options) {
      {
        version: 1,
        layer: 2,
        channels: 2,
        sample_rate: 44100,
        bit_rate: 256,
        per_channel_bit_rate: 128,
        channel_mode: 'Stereo'
      }
    }

    let (:msg) {
      {
        task: {
          id: 'guid4',
          task_type: 'validate',
          label: 'validate',
          job: { id: 1, job_type: 'audio', status: 'created', original: "file:///#{in_file('test_short.mp2')}" },
          options: msg_options
        }
      }.with_indifferent_access
    }

    it "should validate" do
      processor.on_message(msg)
      # {:status=>:complete, :info=>{:errors=>{}, :analysis=>{:size=>179712, :content_type=>"audio/mpeg", :channel_mode=>"Stereo", :bit_rate=>256, :length=>5, :sample_rate=>48000, :version=>1, :layer=>2}}, :message=>"Validate audio complete."}
      processor.result_details[:info][:errors].keys.length.must_equal 0
      processor.result_details[:info][:analysis][:size].must_equal 179712
    end
  end

  describe 'cut_audio' do

    let (:msg) {
      {
        task: {
          id: 'guid4',
          task_type: 'cut',
          label: 'cut',
          job: { id: 1, job_type: 'audio', status: 'created', original: "file:///#{in_file('test_long.wav')}" },
          options: { length: 10, fade: 5 }
        }
      }.with_indifferent_access
    }

    it 'should cut' do
      processor.on_message(msg)
    end
  end
end
