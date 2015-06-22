require 'test_helper'
require 'callbacks/sqs_callback'

class SqsCallbackTest < ActiveSupport::TestCase

  class SqsCallbackTestClass
    include SqsCallback

    def logger
      Rails.logger
    end
  end

  let(:callback) { SqsCallbackTestClass.new }

  let(:web_hook) do
    {
      url: 'sqs://us-east-1/test_fixer_callback',
      message: { result: 'success' }.to_json
    }
  end

  let(:sqs) do
    queue = Minitest::Mock.new
    queue.expect(:queue_url, 'http://sqs.us-east-1.aws.amazon.com/test_fixer_callback')

    sqs = Minitest::Mock.new
    sqs.expect(:create_queue, true, [Hash])
    sqs.expect(:get_queue_url, queue, [Hash])
    sqs.expect(:send_message, true, [Hash])
  end

  it 'can call an sqs callback' do
    callback.sqs = sqs
    callback.sqs_callback(web_hook)
  end
end
