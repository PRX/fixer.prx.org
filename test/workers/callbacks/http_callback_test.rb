require 'test_helper'
require 'callbacks/http_callback'

class HttpCallbackTest < ActiveSupport::TestCase

  let(:callback) { class HttpCallbackTestClass; include HttpCallback; end.new }

  let(:web_hook) do
    {
      url: 'https://thisisatest.com/callback',
      message: { result: 'success' }.to_json
    }
  end

  before {
    WebMock.disable_net_connect!
  }

  after {
    WebMock.allow_net_connect!
  }

  it 'can call an http callback' do
    stub_request(:post, 'https://thisisatest.com/callback').
      with(body: '{"result":"success"}',
           headers: { 'Content-Type' => 'application/json; charset=utf-8', 'Host' => 'thisisatest.com' } ).
      to_return(status: 200, body: 'Processed', headers: {} )

    response = callback.http_callback(web_hook)
    response.status.must_equal 200
  end
end
