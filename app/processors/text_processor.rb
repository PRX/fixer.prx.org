# encoding: utf-8

require 'base_processor'
require 'open_calais'
require 'yahoo_content_analysis'
require 'stringex'

class TextProcessor < BaseProcessor

  task_types ['analyze']

  unless TextProcessor.const_defined?('ANALYSIS_SERVICES')
    ANALYSIS_SERVICES = [:open_calais, :yahoo_content_analysis]
  end

  def analyze_text
    text = File.read(source.path)
    analysis = AnalyzeResult.new
    responses = ANALYSIS_SERVICES.each do |service|
      r = self.send "#{service}_analyze", text
      logger.debug("response from #{service}: #{r.inspect}")
      analysis.merge(r)
    end

    base_file_name = File.basename(source.path) + '.json'
    temp_file = audio_monster.create_temp_file(base_file_name, false)
    temp_file.write analysis.to_json
    temp_file.fsync

    self.destination_format = 'json'
    self.destination = temp_file

    completed_with info_for_analyze(analysis)
  end

  def info_for_analyze(analysis)
    {
      services: ANALYSIS_SERVICES,
      stats:    analysis.stats
    }
  end

  def open_calais_analyze(text)
    credentials = ServiceOptions.service_options(:open_calais)
    client = OpenCalais::Client.new(credentials)
    client.analyze(text)
  end

  def yahoo_content_analysis_analyze(text)
    credentials = ServiceOptions.service_options(:yahoo_content_analysis)
    client = YahooContentAnalysis::Client.new(credentials)
    client.analyze(text)
  end

  class AnalyzeResult

    attr_accessor :language, :topics, :tags, :entities, :relations, :locations

    def initialize
      @language  = ''
      @topics    = []
      @tags      = []
      @entities  = []
      @relations = []
      @locations = []
      # @originals = []
    end

    def stats
      [:topics, :tags, :entities, :relations, :locations].inject({}) do |s, type|
        s[type] = self.send(type).size
        s
      end
    end

    def merge(response)
      self.language ||= response.language
      # @originals << response
      [:topics, :tags, :entities, :relations, :locations].each do |type|
        list      = self.send(type) || []
        submitted = response.send(type) || []
        merge_list(list, submitted)
      end
    end

    def merge_list(list, submitted)
      list_by_name = hash_by_name(list)
      submitted.each do |e|
        norm_name = normalize(e[:name])
        if list_by_name.has_key?(norm_name)

          # puts "merge:\n\t#{list_by_name[norm_name].inspect}\n\t#{e.inspect}"

          # avg score instead of keeping current
          if (e[:score] && e[:score].to_f > 0.0)
            list_by_name[norm_name][:score] = avg([list_by_name[norm_name][:score], e[:score]])
          end

          # reverse merge, i.e. keep list_by_name[norm_name] when there is a collision
          list_by_name[norm_name].reverse_merge!(e)
        else
          list << e
        end
      end
    end

    def avg(array)
      # puts "avg: #{array.inspect}"
      return 0 if !array || array.size < 1
      array.inject(0.0) { |result, el| result + el } / array.size
    end

    def hash_by_name(list)
      name_hash = list.inject({}) do |h, e|
        norm_name = normalize(e[:name])
        h[norm_name] = e
        h
      end
      name_hash
    end

    def normalize(s)
      (s || '').remove_formatting.downcase
    end

  end

end
