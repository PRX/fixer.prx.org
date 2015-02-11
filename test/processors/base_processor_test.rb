require 'test_helper'

class BaseProcessorTest < ActiveSupport::TestCase

  let(:processor) { BaseProcessor.new }

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

    processor.publish_update(task_log: task_log)
  end

  # it 'can symbolize hash' do
  #   processor.symbolize_options({'foo' => 'bar'})[:foo].must_equal 'bar'
  # end

  it 'can access service options' do
    sc = processor.storage_connection('aws')
    sc.wont_be_nil
  end

  it 'cleans backtrace' do
    err = nil
    begin; raise 'fail!'; rescue; err = $!; end
    processor.clean_backtrace(err).must_match /base_processor_test.rb/
  end


end