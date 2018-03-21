require 'test_helper'

class AudioProcessorTest < ActiveSupport::TestCase

  before {
    WebMock.disable_net_connect!
  }

  after {
    WebMock.allow_net_connect!
  }

  let(:audio_monster) do
    Minitest::Mock.new
  end

  let(:processor) {
    p = AudioProcessor.new(logger: Logger.new('/dev/null'))
    p.audio_monster = audio_monster if travis?
    p
  }

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
      if travis?
        audio_monster.expect(:create_temp_file, Tempfile.new('test'), [String])
        audio_monster.expect(:info_for_wav, {:size=>4277159, :content_type=>"audio/vnd.wave", :channel_mode=>"Mono", :bit_rate=>705, :length=>48, :sample_rate=>44100}, [String])
        audio_monster.expect(:loudness_info, {:integrated_loudness=>{:i=>-18.5, :threshold=>-28.6}, :loudness_range=>{:lra=>7.1, :threshold=>-38.7, :lra_low=>-23.6, :lra_high=>-16.5}, :true_peak=>{:peak=>-2.1}}, [String])
        audio_monster.expect(:info_for, { format: 'wav' }, [String])
      end

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
      if travis?
        audio_monster.expect(:create_temp_file, Tempfile.new('test'), [String, false])
        audio_monster.expect(:loudness_info, {:integrated_loudness=>{:i=>-18.5, :threshold=>-28.6}, :loudness_range=>{:lra=>7.1, :threshold=>-38.7, :lra_low=>-23.6, :lra_high=>-16.5}, :true_peak=>{:peak=>-2.1}}, [String])
        audio_monster.expect(:slice_wav, "/tmp/audio_monster/test_long.wav20150528-43657-18y5zb.wav", [String, String, String, String])
        audio_monster.expect(:info_for_wav, {:size=>441044, :content_type=>"audio/vnd.wave", :channel_mode=>"Mono", :bit_rate=>705, :length=>5, :sample_rate=>44100}, [String])
        audio_monster.expect(:info_for, { format: 'wav' }, [String])
      end

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
      if travis?
        audio_monster.expect(:create_temp_file, Tempfile.new('test'), [String])
        # audio_monster.expect(:create_temp_file, Tempfile.new('test'), [String, false])
        audio_monster.expect(:encode_wav_pcm_from_flac, ["0\n", ""], [String, String])
        audio_monster.expect(:tone_detect, [{:start=>5.055, :finish=>6.2, :min=>0.050196286, :max=>0.091354366}], [String, Fixnum, Float, Float])
        audio_monster.expect(:info_for, { format: 'flac' }, [String])
      end

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
      if travis?
        audio_monster.expect(:create_temp_file, Tempfile.new('test'), [String])
        # audio_monster.expect(:create_temp_file, Tempfile.new('test'), [String, false])
        audio_monster.expect(:encode_wav_pcm_from_flac, ["0\n", ""], [String, String])
        audio_monster.expect(:silence_detect, [{:start=>6.168, :finish=>14.999, :min=>0.0, :max=>0.0049678111}], [String, Float, Float])
        audio_monster.expect(:info_for, { format: 'flac' }, [String])
      end

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
      if travis?
        audio_monster.expect(:create_temp_file, Tempfile.new('test'), [String, false])
        audio_monster.expect(:create_wav_wrapped_mp2, true, [String, String, Hash])
        audio_monster.expect(:info_for_wav, {:size=>4277159, :content_type=>"audio/vnd.wave", :channel_mode=>"Mono", :bit_rate=>705, :length=>48, :sample_rate=>44100}, [String])
        audio_monster.expect(:loudness_info, {:integrated_loudness=>{:i=>-18.5, :threshold=>-28.6}, :loudness_range=>{:lra=>7.1, :threshold=>-38.7, :lra_low=>-23.6, :lra_high=>-16.5}, :true_peak=>{:peak=>-2.1}}, [String])
        audio_monster.expect(:info_for, { format: 'mp2' }, [String])
      end

      processor.on_message(msg)
      processor.destination.wont_be_nil
      processor.destination_format.must_equal 'wav'
    end

    it "should create a wave wrapped mp2" do
      if !travis?
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
      if travis?
        audio_monster.expect(:create_temp_file, Tempfile.new('test'), [String])
        audio_monster.expect(:create_temp_file, Tempfile.new('test'), [String, false])
        audio_monster.expect(:encode_wav_pcm_from_mp2, ["0\n", ""], [String, String])
        audio_monster.expect(:info_for, { format: 'mp2' }, [String])
      end

      # stub_request(:post, "https://www.google.com/speech-api/v2/recognize?client=chrome&key=AIzaSyBOti4mM-6x9WDnZIjIeyEU21OpBXqWBgw&lang=en-us&output=json").
      #   with(:headers => { 'Content-Type'=>'audio/x-flac; rate=8000', 'Host'=>'www.google.com:443' } ).
      #   to_return(:status => 200, :body => "", :headers => {})

      processor.stub(:google_transcribe, [ { text: 'the quick brown fox jumped over the lazy dog', confidence: 1.0 } ]) do
        processor.on_message(msg)
        processor.result_details[:info].keys.sort.must_equal [:average_confidence, :character_count, :word_count]
        processor.result_details[:message].wont_be_nil
      end
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

    before {
      if travis?
        audio_monster.expect(:create_temp_file, Tempfile.new('test'), [String])
        audio_monster.expect(:encode_wav_pcm_from_mp2, ["0\n", ""], [String, String])
        audio_monster.expect(:encode_mp3_from_wav, true, [String, String, Hash])
        audio_monster.expect(:info_for_mp3, { size: 90696, content_type: 'audio/mpeg', format: 'mp3', channel_mode: 'JStereo', channels: 2, bit_rate: 128, length: 5.642449, sample_rate: 44100, version: 1, layer: 3, padding: false }, [String])
        audio_monster.expect(:loudness_info, { :integrated_loudness=>{:i=>-18.5, :threshold=>-28.6}, :loudness_range=>{:lra=>7.1, :threshold=>-38.7, :lra_low=>-23.6, :lra_high=>-16.5}, :true_peak=>{:peak=>-2.1}}, [String])
        audio_monster.expect(:info_for, { format: 'mp2' }, [String])
      end
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
          format: 'mp3',
          channel_mode: 'JStereo',
          channels: 2,
          bit_rate: 128,
          length: 5.642449,
          sample_rate: 44100,
          version: 1,
          layer: 3,
          padding: false
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

    before {
      if travis?
        audio_monster.expect(:info_for_mp2, {:size=>179712, :content_type=>"audio/mpeg", :channel_mode=>"Stereo", :bit_rate=>256, :length=>5, :sample_rate=>48000, :version=>1, :layer=>2}, [String])
        audio_monster.expect(:loudness_info, {:integrated_loudness=>{:i=>-18.5, :threshold=>-28.6}, :loudness_range=>{:lra=>7.1, :threshold=>-38.7, :lra_low=>-23.6, :lra_high=>-16.5}, :true_peak=>{:peak=>-2.1}}, [String])
        audio_monster.expect(:info_for, { format: 'mp2' }, [String])
      end
    }

    it "should set destination format" do
      processor.on_message(msg)
      processor.destination.wont_be_nil
      processor.destination_format.must_equal 'mp2'
    end

    it "should copy the file" do
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
      if travis?
        audio_monster.expect(:info_for_mp2, {:size=>179712, :content_type=>"audio/mpeg", :channel_mode=>"Stereo", :bit_rate=>256, :length=>5, :sample_rate=>48000, :version=>1, :layer=>2}, [String])
        audio_monster.expect(:validate_mp2, [{}, {:size=>179712, :content_type=>"audio/mpeg", :channel_mode=>"Stereo", :bit_rate=>256, :length=>5, :sample_rate=>48000, :version=>1, :layer=>2}], [String, Hash])
        audio_monster.expect(:info_for, { format: 'mp2' }, [String])
      end

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
      if travis?
        audio_monster.expect(:create_temp_file, Tempfile.new('test'), [String])
        audio_monster.expect(:info_for_wav, {:size=>4277159, :content_type=>"audio/vnd.wave", :channel_mode=>"Mono", :bit_rate=>705, :length=>48, :sample_rate=>44100}, [String])
        audio_monster.expect(:loudness_info, {:integrated_loudness=>{:i=>-18.5, :threshold=>-28.6}, :loudness_range=>{:lra=>7.1, :threshold=>-38.7, :lra_low=>-23.6, :lra_high=>-16.5}, :true_peak=>{:peak=>-2.1}}, [String])
        audio_monster.expect(:cut_wav, ["0", "sox WARN sox: Option `-s' is deprecated, use `-e signed-integer' instead.", "sox WARN sox: Option `-s' is deprecated, use `-e signed-integer' instead."], [String, String, Fixnum, Fixnum])
        audio_monster.expect(:info_for, { format: 'wav' }, [String])
      end
      processor.on_message(msg)
    end
  end
end
