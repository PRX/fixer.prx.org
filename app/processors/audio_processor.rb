# encoding: utf-8

require 'base_processor'
require 'google_speech'

class AudioProcessor < BaseProcessor

  SUPPORTED_FORMATS = ['aac', 'aif', 'aiff', 'alac', 'flac', 'm4a', 'm4p', 'mp2', 'mp3', 'mp4', 'ogg', 'raw', 'spx', 'wav', 'wma']
  WAVEFORM_WIDTH_MIN = 1800

  attr_accessor :wav_pcm_tempfile

  task_types ['transcode', 'copy', 'analyze', 'validate', 'cut', 'wrap', 'transcribe', 'waveformjson', 'tone_detect', 'silence_detect', 'slice']

  def audio_monster
    @audio_monster ||= ::AudioMonster
  end

  def audio_monster=(am)
    @audio_monster = am
  end

  # make sure to handle 64 kb limit on transcripts
  # perhaps put the transcript/metadata as a result file rather than a response?
  def transcribe_audio
    source_wav = get_wav_from_source

    transcript = google_transcribe(source_wav, options)

    base_file_name = File.basename(source.path) + '.json'
    temp_file= audio_monster.create_temp_file(base_file_name, false)
    temp_file.write transcript.to_json
    temp_file.fsync

    self.destination_format = 'json'
    self.destination = temp_file

    completed_with info_for_transcript(transcript)
  end

  def info_for_transcript(t)
    text = t.collect{|i| i[:text]}.join(' ')
    avg = t.collect{|i| i[:confidence]}.inject(0.0) { |sum, el| sum + el.to_f } / t.size

    {
      average_confidence: avg,
      word_count: text.split.size,
      character_count: text.size
    }
  end

  def google_transcribe(wav, opts={})
    GoogleSpeech.logger = logger
    GoogleSpeech::Transcriber.new(File.open(wav.path), symbolize_options(opts)).transcribe
  end

  def waveformjson_audio
    source_wav = get_wav_from_source

    if options['width_per_second']
      min = options['width_minimum'] && options['width_minimum'].to_i > 0 ? options['width_minimum'].to_i : WAVEFORM_WIDTH_MIN
      width_per_second = options['width_per_second'].to_i
      duration = audio_monster.audio_file_duration(source_wav.path)
      options['width'] = [(duration * width_per_second), min].max
    end

    wf = waveformjson(source_wav, options)
    base_file_name = File.basename(source.path) + '.json'
    temp_file = audio_monster.create_temp_file(base_file_name, false)
    temp_file.write wf.to_json
    temp_file.fsync

    self.destination = temp_file
    self.destination_format = 'json'

    completed_with info_for_waveform(wf)
  end

  def waveformjson(wav, opts={})
    Waveformjson.generate(wav, symbolize_options(opts))
  end

  def info_for_waveform(data)
    { data_count: data.size }
  end

  def loudness_audio
    completed_with audio_monster.loudness_info(source.path)
  end

  # task methods of "#{task_type}_#{job_type}" naming standard
  def transcode_audio
    format = options['format'].to_s
    raise "Unsupported format: '#{format}'" unless SUPPORTED_FORMATS.include?(format)

    self.destination = transcode_to(format, options)
    self.destination_format = format

    completed_with audio_info
  end

  def copy_audio
    self.destination = source
    self.destination_format = source_format

    completed_with audio_info
  end

  def analyze_audio
    completed_with audio_info(source_format, source)
  end

  # this is a stub for the moment - not validating anything yet
  def validate_audio
    errors, analysis = validate(source_format, source, options)
    info = { errors: errors, analysis: analysis }
    completed_with info
  end

  def cut_audio
    source_wav = get_wav_from_source
    task_tmp = audio_monster.create_temp_file(File.basename(source.path))
    audio_monster.cut_wav(source_wav.path, task_tmp.path, options['length'].to_i, (options['fade'] || 5).to_i )

    self.destination_format = 'wav'
    self.destination = task_tmp

    completed_with audio_info
  end

  def slice_audio
    source_wav = get_wav_from_source
    task_tmp = audio_monster.create_temp_file(File.basename(source.path))
    finish = options['finish'].blank? ? '' : "=#{options['finish']}"
    audio_monster.slice_wav(source_wav.path, task_tmp.path, options['start'].to_i, (options['length'] || finish).to_i)

    self.destination_format = 'wav'
    self.destination = task_tmp

    completed_with audio_info
  end

  def tone_detect_audio
    # get a wave for it
    source_wav = get_wav_from_source
    tone = options['tone'] || 25
    threshold = options['threshold'] || 0.05
    min_time = options['min_time'] || 0.5
    ranges = audio_monster.tone_detect(source_wav.path, tone, threshold, min_time)

    completed_with detected_ranges(ranges)
  end

  def silence_detect_audio
    # get a wave for it
    source_wav = get_wav_from_source
    threshold = options['threshold'] || 0.005
    min_time = options['min_time'] || 1.0
    # puts "t: #{threshold}, m: #{min_time}"
    ranges = audio_monster.silence_detect(source_wav.path, threshold, min_time)

    completed_with detected_ranges(ranges)
  end

  def detected_ranges(ranges)
    ranges.collect{|r| [r[:start], r[:finish]] }
  end

  def wrap_audio
    task_tmp = audio_monster.create_temp_file(File.basename(source.path))
    if source_format == 'wav'
      audio_monster.add_cart_chunk_to_wav(source.path, task_tmp.path, options)
    elsif ['mp2', 'mp3'].include?(source_format)
      audio_monster.create_wav_wrapped_mp2(source.path, task_tmp.path, options)
    end

    self.destination_format = 'wav'
    self.destination = task_tmp

    completed_with audio_info
  end

  def extract_result_options(result_uri_string)
    uri, options = super

    if uri.scheme == 's3'
      if @result_details[:info] && @result_details[:info][:content_type]
        options[:content_type] = @result_details[:info][:content_type]
      end
    end

    return [uri, options]
  end

  def symbolize_options(options)
    Hash[options.map{|(k,v)| [k.to_sym,v]}]
  end

  def validate(format, file, opts)
    if format == 'mp2'
      audio_monster.send("validate_#{format}".to_sym, file.path, opts)
    else
      raise "Format: #{format} not supported. Only validating mp2 is currently supported."
    end
  end

  # helper methods
  def audio_info(format=destination_format, file=destination)
    info = audio_monster.send("info_for_#{format}".to_sym, file.path) || {}
    info[:loudness] = audio_monster.loudness_info(file.path)
    info
  end

  def transcode_to(format, opts)
    # if the requested format is wav, well, we are done, short circuit here
    if format == 'wav'
      transcode_tmp = get_wav_from_source
    else
      transcode_tmp = audio_monster.create_temp_file(File.basename(source.path + ".#{format}"))
      audio_monster.send("encode_#{format}_from_wav", get_wav_from_source.path, transcode_tmp.path, opts)
    end
    transcode_tmp
  end

  def get_wav_from_source
    if !wav_pcm_tempfile && source_format == 'wav'
      wav = NuWav::WaveFile.parse(source.path)
      if wav.is_pcm?
        self.wav_pcm_tempfile = source
      else
        logger.info "#{source.path} is not a pcm wav."
      end
    end

    if !wav_pcm_tempfile
      wav_tmp = audio_monster.create_temp_file(File.basename(source.path + ".wav"))
      audio_monster.send("encode_wav_pcm_from_#{source_format}".to_sym, source.path, wav_tmp.path)
      self.wav_pcm_tempfile = wav_tmp
    end

    wav_pcm_tempfile
  end

  def prepare_task
    release_tempfile(wav_pcm_tempfile)
    self.wav_pcm_tempfile = nil
  end

  def complete_task
    release_tempfile(wav_pcm_tempfile)
    self.wav_pcm_tempfile = nil

    release_tempfile(source)
    self.source = nil

    release_tempfile(original)
    self.original = nil
  end

  def release_tempfile(tmp)
    if(tmp && tmp.is_a?(Tempfile))
      tmp.close
      File.unlink(tmp) if SystemInformation.env == 'production'
    end
  rescue Exception => err
    logger.error "release_wav_tmp: err #{err.inspect}"
  end
end
