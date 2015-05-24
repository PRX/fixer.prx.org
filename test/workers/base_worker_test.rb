require 'test_helper'

class BaseWorkerTest < ActiveSupport::TestCase

  class EchoWorker < BaseWorker
    queue_as :test_queue

    def perform(*args)
      e = JSON.parse(args.first)
      e['echo']
    end
  end

  it 'knows the worker lib' do
    BaseWorker.worker_lib.must_equal 'test'
  end

  it 'calls worker perform' do
    EchoWorker.new.perform({echo: 'bar'}.to_json).must_equal 'bar'
  end
end
