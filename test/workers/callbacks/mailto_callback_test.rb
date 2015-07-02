require 'test_helper'
require 'callbacks/mailto_callback'

class MailtoCallbackTest < ActionMailer::TestCase

  let(:callback) { class MailtoCallbackTestClass; include MailtoCallback; end.new }

  let(:web_hook) do
    {
      url: 'mailto:example@foo.com',
      message: { result: 'success' }.to_json,
      informer_status: 'completed',
      informer_type: 'job',
      informer_id: 'abc123'
    }
  end

  it 'sends a mail callback' do
    ActionMailer::Base.deliveries.must_be :empty?
    callback.mailto_callback(web_hook)
    ActionMailer::Base.deliveries.wont_be :empty?
  end
end
