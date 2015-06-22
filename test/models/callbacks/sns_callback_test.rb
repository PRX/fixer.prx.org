require 'test_helper'
require 'callbacks/sns_callback'

class SnsCallbackTest < ActiveSupport::TestCase

  class SnsCallbackTestClass
    include SnsCallback

    def logger
      Rails.logger
    end
  end

  let(:callback) { SnsCallbackTestClass.new }

  let(:web_hook) do
    {
      url: 'sns://us-east-1/test_fixer_callback',
      message: { result: 'success' }.to_json
    }
  end

  let(:sns) do
    topic = Minitest::Mock.new
    topic.expect(:topic_arn, 'arn:aws:sns:us-east-1:111111111111:test_fixer_callback')

    sns = Minitest::Mock.new
    sns.expect(:create_topic, topic, [Hash])
    sns.expect(:publish, true, [Hash])
  end

  it 'can call an sns callback' do
    callback.sns = sns
    callback.sns_callback(web_hook)
  end
end
