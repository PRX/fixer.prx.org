require 'test_helper'

class BaseWorkerTest < ActiveSupport::TestCase

  class EchoWorker < BaseWorker
    def perform(*args)
      args.first[:echo]
    end
  end

  before {
    ENV['FIXER_WORKER_LIB'] = 'local'
  }

  it 'knows the worker lib' do
    BaseWorker.worker_lib.must_equal 'local'
  end

  it 'can configure options' do
    BaseWorker.worker_options({foo: 'bar'})
    BaseWorker.get_local_options[:foo].must_equal 'bar'
  end

  it 'calls worker perform' do
    EchoWorker.publish('test-queue', {echo: 'bar'}, {}).must_equal 'bar'
  end
end
