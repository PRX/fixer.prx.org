require 'test_helper'

class BaseProcessorTest < ActiveSupport::TestCase

  let(:processor) { BaseProcessor.new }

  let(:task_message) {
    {
      'task' => {
        'id'  => 1,
        'task_type' => 'test',
        'job' => 'job'
      }
    }
  }

  let(:sequence_message) {
    {
      'sequence' => {
        'job'    => 'job',
        'tasks'  => [ { 'id' => 2 },{ 'id' => 3 } ]
      }
    }
  }

  describe 'class methods' do

    it 'can set task types' do
      BaseProcessor.task_types ['foo']
      BaseProcessor.supported_tasks.first.must_equal 'foo'
    end

    it 'determines job type from class name' do
      BaseProcessor.job_type.must_equal 'base'
    end

    it 'has a default logger' do
      BaseProcessor.logger.wont_be_nil
    end

  end

  it 'sets logger and options on init' do
    p = BaseProcessor.new(logger: 'foo', options: 'bar')
    p.logger.must_equal 'foo'
    p.options.must_equal 'bar'
  end

  it 'can publish an update' do
    logged_at = Time.now
    task_log = {
      logged_at: logged_at,
      task_id: 'thisisnotarealuuid',
      status: 'created',
      info: {
        started_at: logged_at
      },
      message: 'created'
    }

    TaskUpdateWorker.stub :publish, 'cool' do
      log = processor.publish_update(task_log: task_log)
      log[:task_log][:status].must_equal 'created'
    end

  end

  it 'prepares task based on message' do
    processor.prepare(task_message)
    processor.task['id'].must_equal 1
    processor.job.must_equal 'job'
    processor.tasks.length.must_equal 1
    processor.sequence.must_be_nil
  end

  it 'prepares sequence based on message' do
    processor.prepare(sequence_message)
    processor.sequence.wont_be_nil
    processor.task['id'].must_equal 2
    processor.job.must_equal 'job'
    processor.tasks.length.must_equal 2
  end

  it 'handles a task message' do
    # stub process
    def processor.process; self.result_details = { status: 'test' }; end
    processor.on_message(task_message)
    processor.task['id'].must_equal 1
    processor.result_details[:status].must_equal 'test'
  end

  it 'will process all tasks' do
    def processor.process_task(t); self.result_details = { task: t }; end
    processor.prepare(task_message)
    processor.process
    processor.result_details[:task].must_equal task_message['task']
  end

  it 'processes and executes task' do
    def processor.test_base; { status: 'test_base' }; end
    BaseProcessor.task_types ['test']

    processor.prepare(task_message)
    processor.process_task(task_message['task'])
    processor.result_details[:status].must_equal 'test_base'
  end

  it 'closes open files' do
    processor.source = File.open(out_file('test_close.txt'), 'w')
    processor.source.wont_be :closed?

    processor.close_files
    processor.source.must_be :closed?
  end

  it 'saves the resulting file' do
    processor = BaseProcessor.new
    processor.task = { 'result' => 'file://test.fixer.org/store_result.ogg' }
    processor.destination = File.open(in_file('test.ogg'))
    result = processor.store_result
    result.must_match /test\.fixer\.org\/store_result\.ogg$/
    assert File.exists?(result)
  end

  describe 'extract url options' do

    it 'handles no options' do
      uri, options = processor.extract_result_options("ftp://foo.bar.com/")
      uri.wont_be_nil
      options.wont_be_nil
      options.keys.count.must_equal 0
      uri.query.must_equal nil
      uri.to_s.must_equal "ftp://foo.bar.com/"
    end

    it 'parses options' do
      uri, options = processor.extract_result_options("ftp://foo.bar.com/?x-fixer-foo=1&bar=2")
      uri.wont_be_nil
      options.wont_be_nil
      options['foo'].must_equal '1'
      uri.query.must_equal 'bar=2'
    end

    it 'allows access on options indifferently' do
      uri, options = processor.extract_result_options("ftp://foo.bar.com/?x-fixer-test_option=2")
      options[:test_option].must_equal '2'
    end
  end

  it 'uploads a file based on url scheme' do
    def processor.ftp_upload_file(u,f,o); 'uploaded!'; end

    uri = URI.parse('ftp://this/file.txt')
    file = File.open(in_file('test.ogg'))
    processor.upload_file(uri, file, {}).must_equal 'uploaded!'
  end

  it 'lists supported upload schemes' do
    processor.upload_schemes.must_be :include?, 'file'
  end

  it 'updates when processing starts' do
    processor.task = { id: '123' }

    TaskUpdateWorker.stub :publish, "awesome" do
      log = processor.notify_task_processing
      log[:task_log][:status].must_equal 'processing'
    end
  end

  it 'updates the task' do
    processor.task = { 'id' => '345' }
    processor.result_details = {status: 'test'}

    TaskUpdateWorker.stub :publish, "superb" do
      log = processor.update_task
      log[:task_log][:status].must_equal 'test'
      log[:task_log][:task_id].must_equal '345'
    end
  end

  it 'downloads the original' do
    processor.job = { 'original' => "file://#{in_file('test.ogg')}"}
    processor.download_original

    processor.original.wont_be_nil
    processor.original_format.must_equal 'ogg'
  end

  it 'extracts format from uri' do
    uri = URI.parse 'file://what/test.mp3?wat=dat'
    processor.extract_format(uri).must_equal 'mp3'
  end

  it 'downloads a file based on url scheme' do
    def processor.ftp_download_file(u); 'downloaded!'; end

    uri = URI.parse('ftp://this/file.txt')
    processor.download_file(uri).must_equal 'downloaded!'
  end

  it 'lists supported download schemes' do
    processor.download_schemes.must_be :include?, 'file'
  end

  it 'handles standard errors' do
    processor.task = { 'id' => '456' }
    begin; raise 'fail!'; rescue; err = $!; end

    TaskUpdateWorker.stub :publish, "superb" do
      log = processor.on_error(err)
      log[:task_log][:status].must_equal 'error'
      log[:task_log][:task_id].must_equal '456'
    end
  end

  it 'cleans backtrace' do
    err = nil
    begin; raise 'fail!'; rescue; err = $!; end
    processor.clean_backtrace(err).must_match /base_processor_test.rb/
  end

  it 'can access service options by provider' do
    sc = processor.storage_connection('aws')
    sc.must_be_instance_of Fog::Storage::AWS::Real
  end

  it 'can access storage connection by uri' do
    uri = URI.parse("s3://this.is.my.bucket/path/key/file.mp3")
    sc = processor.storage_connection(uri)
    sc.must_be_instance_of Fog::Storage::AWS::Real
  end
end
