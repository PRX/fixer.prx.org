require 'uri'
require 'json'
require 'fog'
require 'rack'
require 'service_options'
require 'system_information'

%W(ftp ia http s3).each{|f| require "concerns/#{f}_files" }

class BaseProcessor

  include FixerConstants

  include FtpFiles
  include IaFiles
  include HttpFiles
  include S3Files

  attr_accessor :message, :options, :job, :sequence, :tasks, :task, :result_details, :original, :original_format, :source, :source_format, :destination, :destination_format, :logger

  class << self
    attr_accessor :supported_tasks, :job_type

    def task_types(tasks)
      self.supported_tasks = tasks
    end

    def job_type
      @job_type ||= name.underscore.gsub(/_processor/, '')
    end

    def logger
      @_logger = defined?(Rails) ? Rails.logger : Logger.new(STDOUT)
    end
  end

  def initialize(opts={})
    self.logger = opts[:logger]
    self.options = opts[:options]
  end

  def completed(info, message)
    { status: COMPLETE, info: info, message: message }
  end

  def publish_update(log)
    TaskUpdateWorker.publish(:task_update, log)
    log
  end

  def on_message(message)
    prepare(message)
    process
  rescue Object=>err
    begin
      on_error(err)
    rescue Object=>ex
      logger.error "Processor:process! - error in on_error, will propagate no further: #{ex.message}\n\t#{ex.backtrace.join("\n\t")}"
      raise ex
    end
  end

  # set job, sequence, tasks, task, and original
  def prepare(amessage=nil)
    self.message = amessage if amessage
    logger.info "BaseProcessor.prepare: #{message}"

    if message['sequence']
      self.sequence = message['sequence']
      self.job      = sequence.delete('job')
      self.tasks    = sequence.delete('tasks')
      self.task     = tasks.first
    elsif message['task']
      self.task     = message['task']
      self.job      = task.delete('job')
      self.tasks    = [task]
      self.sequence = nil
    end
  end

  # set source and destination
  def process
    # start with the original as if it was the last destination
    tasks.each do |t|
      process_task(t)
    end
    close_files
  end

  def process_task(atask)
    self.task = atask if atask

    self.options = nil

    # task identified and assigned, notify server that processing is beginning
    notify_task_processing

    # make sure we have downloaded the original
    download_original

    # if in a sequence, use the prior task destination if there is one, else use the original as the source
    if destination
      self.source = destination
      self.source_format = destination_format
    else
      self.source = original
      self.source_format = original_format
    end

    # destination needs to be nil as task starts, and now that we have gotten prior value for the source
    self.destination = nil

    # run the task!
    prepare_task
    execute_task
    store_result
    update_task
    complete_task
  end

  # these are temp files, and should just go away, but let's be proactive
  def close_files
    [self.source, self.original, self.destination].each do |f|
      next unless f
      f.close rescue nil
      File.unlink(f) rescue nil
    end
  end

  # abstract, child processors can implement this hook
  def prepare_task
  end

  # valid tasks validate, transcode
  def execute_task
    task_type = task['task_type'].to_s

    unless supported_tasks.include?(task_type)
      raise "Unsupported task type: #{task_type}, valid options: #{supported_tasks.inspect}"
    end

    # call the method to execute the task based on task and job type
    self.result_details = self.send("#{task_type}_#{job_type}".to_sym)
  end

  def store_result
    result = task['result']
    return unless destination && result

    uri, opts = extract_result_options(result)
    upload_file(uri, destination, opts)
  end

  def extract_result_options(result_uri_string)
    uri = URI.parse(result_uri_string)

    # get any params from the uri query string
    query_params = Rack::Utils.parse_nested_query(uri.query)

    # get all the options from the params that include x-fixer- prefix
    opts = {}
    params = {}

    query_params.each_pair do |k,v|
      if k.to_s.starts_with?('x-fixer-')
        opts[k[8..-1]] = v
      else
        params[k] = v
      end
    end

    # update the uri to remove any of the x-fixer- params
    uri.query = params.keys.count > 0 ? params.to_query : nil

    return [uri, opts.with_indifferent_access]
  end

  def upload_file(uri, file, opts)
    unless upload_schemes.include?(uri.scheme)
      raise "store_result: #{uri.scheme} not supported."
    end

    send("#{uri.scheme}_upload_file", uri, file, opts)
  end

  def upload_schemes
    @_upload_schemes ||= begin
      s = ['s3', 'ia', 'ftp']
      s << 'file' if ServiceOptions.env != 'production'
    end
  end

  def notify_task_processing
    logged_at = Time.now
    logger.info "notify_task_processing: #{logged_at}, task: #{task['id']}"

    task_log = {
      logged_at: logged_at,
      task_id: task['id'],
      status: PROCESSING,
      info: {
        started_at: logged_at
      },
      message: 'Processing started.'
    }

    publish_update(task_log: task_log)
  end

  def update_task
    logged_at = Time.now
    logger.info "update_task: #{logged_at}, task: #{task['id']}, result_details: #{result_details.inspect}"
    task_log = {
      logged_at: logged_at,
      task_id: task['id']
    }.merge(result_details)

    publish_update(task_log: task_log)
  end

  # abstract
  def complete_task
  end

  def download_original
    # now try and get the original
    unless original && original_format
      return unless job['original']
      uri = nil
      if job['original'].is_a?(String)
        uri = URI.parse(job['original'])
        self.original_format = extract_format(uri)
      elsif job['original'].is_a?(Hash)
        uri = URI.parse(job['original']['url'])
        self.original_format = job['original']['format']
      end
      self.original = download_file(uri)
    end
  end

  def extract_format(uri)
    File.extname((uri.path || '').split('/').last).downcase[1..-1]
  end

  def download_file(uri)
    unless download_schemes.include?(uri.scheme)
      raise "download_file: #{uri.scheme} not supported."
    end

    send("#{uri.scheme}_download_file", uri)
  rescue StandardError => err
    logger.error "BaseProcessor download_file: #{err.class.name}\n#{err.message}\n\t" + err.backtrace.join("\n\t")
    raise "Could not download file '#{uri}': #{err.message}"
  end

  def download_schemes
    @_download_schemes ||= begin
      s = ['s3', 'ia', 'ftp', 'http']
      s << 'file' if ServiceOptions.env != 'production'
    end
  end

  def file_download_file(uri)
    local_file_path = uri.host ? File.join(uri.host, uri.path) : uri.path
    raise "File does not exist: #{local_file_path}" unless File.exists?(local_file_path)
    File.open(local_file_path)
  end

  def file_upload_file(uri, file, opts={})
    local_file_path = File.join(temp_directory, (uri.host ? File.join(uri.host, uri.path) : uri.path))
    FileUtils.mkdir_p(File.dirname(local_file_path))
    FileUtils.cp(file.path, local_file_path)
    local_file_path
  end

  def temp_directory
    File.expand_path(File.join(ServiceOptions.root,'tmp','fixer'))
  end

  def storage_connection(uri, opts={})
    service_opts = ServiceOptions.options_for_uri(uri) || ServiceOptions.service_options(uri)
    Fog::Storage.new(service_opts.merge(opts))
  end

  # Default on_error implementation - logs standard errors but keeps processing. Other exceptions are raised.
  # Have on_error throw ActiveMessaging::AbortMessageException when you want a message to be aborted/rolled back,
  # meaning that it can and should be retried (idempotency matters here).
  # Retry logic varies by broker - see individual adapter code and docs for how it will be treated
  def on_error(err)
    logger.error "BaseProcessor on_error: #{err.class.name}\n#{err.message}\n\t" + err.backtrace.join("\n\t")
    log = nil

    if (task && task['id'])

      task_log = {
        logged_at: Time.now,
        task_id: task['id'],
        status: ERROR,
        info: {
          class: err.class.name,
          trace: clean_backtrace(err)
        },
        message: err.message.split("\n").first
      }

      logger.error "BaseProcessor on_error: publish task_log error: #{task_log.inspect}"
      log = publish_update(task_log: task_log)
    end

    if (err.kind_of?(StandardError))
      logger.error "BaseProcessor::on_error: #{err.class.name} rescued: " + err.message
    else
      logger.error "BaseProcessor::on_error: #{err.class.name} raised: " + err.message
      raise err
    end

    log
  end

  def clean_backtrace(err)
    bc = ActiveSupport::BacktraceCleaner.new
    bc.add_filter   { |line| line.gsub(ServiceOptions.root.to_s, '') }
    bc.add_silencer { |line| line =~ /gems|lib\/ruby/ }
    backtrace = bc.clean(err.backtrace).join("\n")
    backtrace[0..60000]
  end

  def options
    @options ||= ((task && task['options']) || {})
  end

  def logger
    @logger ||= BaseProcessor.logger
  end

  def job_type
    self.class.job_type
  end

  def supported_tasks
    self.class.supported_tasks || []
  end
end
